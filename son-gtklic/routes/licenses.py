
import sys
import os
import ast
from datetime import datetime, timedelta
from flask_restful import Resource
from flask import request

from models import License, Type
from app import db, build_response

class LicensesList(Resource):

    def get(self):
        if 'user_uuid' in request.args:
            licenses = License.query.filter_by(user_uuid=request.args.get('user_uuid')).all()
        else:
            licenses = License.query.all()

        return build_response(status_code=200, data={"licenses": [o.serialize for o in licenses]}, description="Licenses list successfully retrieved")

    def post(self):
        try:
            service_uuid=request.form['service_uuid']
            user_uuid = request.form['user_uuid']
            type_uuid=request.form['type_uuid']

            license = License.query.filter_by(  user_uuid=user_uuid,
                                                service_uuid=service_uuid,
                                                type_uuid=type_uuid
                                              ).first()
            if license != None:
                return build_response(status_code=304, error="Already exists", description="License for that user to that service of this type already exists", data=license.serialize)

            license_type = Type.query.filter_by(type_uuid=request.form['type_uuid']).first()
            if license_type is None:
                return build_response(status_code=404, error="Not Found", description="License type provided does not exist")
            if license_type.active == False:
                return build_response(status_code=400, error="Not Active", description="License type required exists but is not active")

            startingDate = datetime.now()
            if not (request.form.get('startingDate') is None):
                startingDate = datetime.strptime(str(request.form.get('startingDate')), "%d-%m-%Y %H:%M")

            expiringDate = startingDate + timedelta(days=license_type.duration)

            active = True
            if 'active' in request.form:
                try:
                    active = ast.literal_eval(request.form.get('active'))
                except:
                    return build_response(status_code=400, error="Invalid field", description="Active parameter was not a boolean")

            new_license = License(  license_type.type_uuid,
                                    service_uuid,
                                    request.form['user_uuid'],
                                    request.form.get('description'),
                                    startingDate,
                                    expiringDate,
                                    suspended=(not active))
                                    
        except:
            return build_response(status_code=400, error="Missing fields", description="Missing type_uuid, service_uuid or user_uuid argument")

        db.session.add(new_license)
        db.session.commit()
        return build_response(status_code=200, data=new_license.serialize, description="License successfully created")


class Licenses(Resource):

    def head(self, licenseID):
        license = License.query.get(licenseID)
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License does not exist")

        if not license.active:
            return build_response(status_code=400, data="", error="License is not valid")

        if license.suspended:
            return build_response(status_code=400, data="", error="License is not valid")

        if license.startingDate > datetime.now():
            build_response(status_code=400, data="", error="License is not valid")

        if license.expiringDate < datetime.now():
            build_response(status_code=400, data="", error="License is not valid")

        return build_response(status_code=200, data="", description="License is valid")

    def get(self, licenseID):

        license = License.query.get(licenseID)
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License does not exist")

        if not license.active:
            return build_response(status_code=400, data=license.serialize, error="License is not valid")

        if license.suspended:
            return build_response(status_code=400, data=license.serialize, error="License is not valid")

        if license.startingDate > datetime.now():
            return build_response(status_code=400, data=license.serialize, error="License is not valid")

        if license.expiringDate < datetime.now():
            return build_response(status_code=400, data=license.serialize, error="License is not valid")

        return build_response(status_code=200, data=license.serialize, description="License is valid")

    def post(self, licenseID):
        try:
            license = License.query.get(licenseID)
            if license is None:
                return build_response(status_code=404, error="Not Found", description="License ID provided does not exist")

            if 'user_uuid' not in request.form:
                return build_response(status_code=400, error="Missing Field", description="user_uuid was not provided")

            if license.user_uuid != request.form['user_uuid']:
                return build_response(status_code=400, error="Invalid User", description="user_uuid provided is not the one that owns the license")

            license_type = Type.query.get(license.type_uuid)
            if 'type_uuid' in request.form:
                license_type = Type.query.get(request.form['type_uuid'])
                if not license_type:
                    return build_response(status_code=404, error="Invalid License Type", description="License type provided to change does not exist")
                license.type_uuid = license_type.type_uuid

            baseExpiringDate = license.expiringDate
            if license.expiringDate < datetime.now():
                baseExpiringDate = datetime.now()

            license.expiringDate = baseExpiringDate + timedelta(days=license_type.duration)

        except:
            return build_response(status_code=400, error="Invalid arguments", description="Arguments provided were invalid")

        db.session.commit()

        return build_response(status_code=200, data=license.serialize, description="License successfully renewed")

    def put(self, licenseID):
        license = License.query.filter_by(license_uuid=licenseID).first()
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License ID provided does not exist")

        if not license.active:
            return build_response(status_code=400, error="Not Valid", description="License ID provided is cancelled")

        if license.suspended:
            return build_response(status_code=304, error="Already Suspended", description="License ID provided is already suspended")

        license.suspended = True
        db.session.commit()

        return build_response(status_code=200, data=license.serialize, description="License successfully suspended")

    def delete(self, licenseID):
        license = License.query.filter_by(license_uuid=licenseID).first()
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License ID provided does not exist")

        if not license.active:
            return build_response(status_code=304, error="Not Valid", description="License ID provided is already cancelled")

        license.active = False
        db.session.commit()

        return build_response(status_code=200, data=license.serialize, description="License successfully cancelled")
