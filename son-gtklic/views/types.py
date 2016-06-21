
import sys
import os
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import Type
from db import db_session


class TypesList(Resource):

    def get(self):
        type = Type.query.all()

        return jsonify({"types": [o.serialize for o in type]})


    def post(self):
        new_type = Type(request.form['type'])
        db_session.add(new_type)
        db_session.commit()

        return new_type.serialize, 200


class Types(Resource):

    def delete(self, typeID):
        type = Type.query.filter_by(type_uuid=typeID).first()

        if type is None:
            return "Type ID not found", 404

        type.active = False
        db_session.commit()

        return jsonify(type.serialize)

