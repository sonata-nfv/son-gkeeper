
import sys
import os
from datetime import datetime
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify, make_response

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import License, Type
from db import db_session


class LicensesList(Resource):

    def get(self):
        if request.form['user_uuid'] is None:
            return "No user uuid provided", 404

        licenses = License.query.filter(user_uuid=request.form['user_uuid']).all()

        return jsonify({"licenses": [o.serialize for o in licenses]})


    def post(self):

        try:
            license_type = Type.query.filter_by(type_uuid=request.form['type_uuid']).get()

            # Doesnt work need to be done
            expiringDate = None
            #expiringDate = request.form['startingDate'] + license_type.duration


            new_license = License(request.form['type_uuid'], request.form['service_uuid'], request.form['user_uuid'],
                                  request.form['description'], request.form['startingDate'], expiringDate, )
        db_session.add(new_license)
        db_session.commit()

        return new_license.serialize


class Licenses(Resource):

    def head(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).get()
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
        license = License.query.filter(license_uuid=licenseID).get()
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
        pass

    def put(self, licenseID):
        license = License.query.filter(license_uuid=licenseID).get()

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
        license = License.query.filter(license_uuid=licenseID).get()

        if license is None:
            return "License ID not found", 404

        if not license.active:
            response = jsonify(license.serialize)
            response.status_code = 304
            return response

        license.active = False
        db_session.commit()

        return jsonify(license.serialize)


