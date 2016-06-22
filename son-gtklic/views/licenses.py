
import sys
import os
from datetime import datetime
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import License, Purchase
from db import db_session


class LicensesList(Resource):

    def get(self):
        if request.form['user_uuid'] is None:
            return "No user uuid provided", 404

        licenses = License.query.filter(user_uuid=request.form['user_uuid']).all()

        return jsonify({"licenses": [o.serialize for o in licenses]})


    def post(self):
        if request.form['user_uuid'] is None:
            return "No user uuid provided", 404

        if request.form['user_uuid'] is None:
            return "No user uuid provided", 404

        new_license = License(request.form['type'])
        db_session.add(new_license)
        db_session.commit()

        return new_type.serialize, 200


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
        pass

    def put(self, licenseID):
        pass

    def delete(self, licenseID):
        type = Type.query.filter_by(type_uuid=licenseID).first()

        if type is None:
            return "Type ID not found", 404

        type.active = False
        db_session.commit()

        return jsonify(type.serialize)


