
import datetime
import uuid
import sys
import os
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from sqlalchemy.dialects.postgresql import UUID

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import Type
from db import db_session



class TypesList(Resource):

    def get(self):
        return "Hello", 200

    def post(self):
        new_type = Type(request.form['type'])
        db_session.add(new_type)
        db_session.commit()

        return new_type.serialize, 200

class Types(Resource):
    def post(self, typeID):



        return "Hello", 200
