
from flask_restful import reqparse, abort, Api, Resource

class TypesList(Resource):
    def get(self):
        return "Hello", 200

class Types(Resource):
    def post(self, typeID):
        return "Hello", 200
