
import sys
import os
from datetime import datetime, timedelta
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify, make_response

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import License, Type, Service
from db import db_session


class LicensesList(Resource):

    def get(self):
        if request.form['user_uuid'] is None:
            return "No user uuid provided", 404

        licenses = License.query.filter(user_uuid=request.form['user_uuid']).all()

        return jsonify({"licenses": [o.serialize for o in licenses]})


    def post(self):

        try:
            license_type = Type.query.filter_by(type_uuid=request.form['type_uuid']).first()

            if license_type is None:
                return "License type not found", 404

            service = Service.query.filter_by(service_uuid=request.form['service_uuid']).first()


            if service is None:
                return "Service not found", 404

            startingDate = datetime.now()
            if not (request.form.get('startingDate') is None):
                startingDate = datetime.strptime(str(request.form.get('startingDate')), "%d-%m-%y %H:%M")

            expiringDate = startingDate + timedelta(days=license_type.duration)

            if expiringDate > service.expiringDate:
                return "Service no longer available for the license period", 410

            new_license = License(license_type.type_uuid, service.service_uuid, request.form['user_uuid'],
                                  request.form['description'], startingDate, expiringDate, request.form['active'])

        except:
            return "Invalid arguments", 400
        db_session.add(new_license)
        db_session.commit()

        return new_license.serialize


class Licenses(Resource):

    def head(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).first()

        if license is None:
            return "License doesn't exist", 404

        if license.user_uuid != request.form['user_uuid']:
            return "Service user doesn't have that license", 401

        if license.startingDate > datetime.now():
            return "License not valid", 403

        if license.expiringDate < datetime.now():
            return "License not valid", 403

        return "License is valid", 200

    def get(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).first()

        if license is None:
            return "License doesn't exist", 404

        if license.user_uuid != request.form['user_uuid']:
            return "Service user doesn't have that license", 401

        if license.startingDate > datetime.now():
            return "License not valid", 403

        if license.expiringDate < datetime.now():
            return "License not valid", 403

        return jsonify(license.serialize)

    def post(self, licenseID):
        try:
            license = License.query.filter_by(license_uuid=licenseID).first()

            license_type = Type.query.filter_by(type_uuid=license.type_uuid).first()

            service = Service.query.filter_by(service_uuid=license.service_uuid).first()


            new_date = license.expiringDate + timedelta(days=license_type.duration)

            if new_date > service.expiringDate:
                return "Service no longer available for the license period", 410

            license.expiringDate = new_date

        except:
            return "Invalid arguments", 400

        db_session.commit()

        return jsonify(license.serialize)


    def put(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).first()

        if license is None:
            return "License ID not found", 404

        if license.suspended:
            response = jsonify(license.serialize)
            response.status_code = 304
            return response

        license.suspended = True
        db_session.commit()

        return jsonify(license.serialize)

    def delete(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).first()

        if license is None:
            return "License ID not found", 404

        if not license.active:
            response = jsonify(license.serialize)
            response.status_code = 304
            return response

        license.active = False
        db_session.commit()

        return jsonify(license.serialize)


