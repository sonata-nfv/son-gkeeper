
import sys
import os
import ast
import requests
from datetime import datetime, timedelta
from flask_restful import Resource
from flask import request

from models import License
from app import db, build_response, app

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

            license = License.query.filter_by(  user_uuid=user_uuid,
                                                service_uuid=service_uuid
                                              ).first()
            if license != None:
                return build_response(status_code=400, error="Already exists", description="License for that user to that service already exists", data=license.serialize)

            license_type = "PUBLIC"
            if 'license_type' in request.form:
                if request.form["license_type"].upper() in License.license_types:
                    license_type = request.form["license_type"].upper()
                else:
                    return build_response(status_code=400, error="Invalid field", description="License type parameter was invalid")

            validation_url = None
            if license_type == "PRIVATE":
                if 'validation_url' not in request.form:
                    return build_response(status_code=400, error="Missing fields", description="Missing validation_url field for private license type")
                else:
                    validation_url = request.form['validation_url']

            status = "ACTIVE"
            if 'status' in request.form:
                if request.form["status"].upper() in License.valid_status:
                    status = request.form["status"].upper()
                else:
                    return build_response(status_code=400, error="Invalid field", description="Status parameter was invalid")

            new_license = License(  service_uuid,
                                    user_uuid,
                                    request.form.get('description'),
                                    validation_url,
                                    status,
                                    license_type)

        except:
            return build_response(status_code=400, error="Missing fields", description="Missing service_uuid or user_uuid argument")

        db.session.add(new_license)
        db.session.commit()
        return build_response(status_code=200, data=new_license.serialize, description="License successfully created")


class Licenses(Resource):

    def head(self, licenseID):
        license = License.query.get(licenseID)
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License does not exist")

        if validate_license(license):
            return build_response(status_code=200, data="", description="License is valid")
        else:
            return build_response(status_code=400, data="", error="License is not valid")

    def get(self, licenseID):
        license = License.query.get(licenseID)
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License does not exist")

        if validate_license(license):
            return build_response(status_code=200, data=license.serialize, description="License is valid")
        else:
            return build_response(status_code=400, data="", error="License is not valid")


    def delete(self, licenseID):
        license = License.query.filter_by(license_uuid=licenseID).first()
        if license is None:
            return build_response(status_code=404, error="Not Found", description="License ID provided does not exist")

        if license.status == "INACTIVE":
            return build_response(status_code=304, error="Not Modified", description="License ID provided is already cancelled")

        license.status = "INACTIVE"
        if license.license_type == "PRIVATE":
            response = requests.delete(license.validation_url, timeout=app.config["TIMEOUT"])
            if not response.status_code == 200:
                return build_response(status_code=400, error="Not Allowd", description="Validate URL failed to cancel the license")

        db.session.commit()

        return build_response(status_code=200, data=license.serialize, description="License successfully cancelled")



def validate_license(license):
    if not license.status == "ACTIVE":
        return False

    if license.license_type == "PRIVATE":
        response = requests.get(license.validation_url, timeout=app.config["TIMEOUT"])
        if not response.status_code == 200:
            return False

    return True
