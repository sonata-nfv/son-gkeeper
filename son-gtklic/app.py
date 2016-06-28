
from flask import Flask
from flask_restful import reqparse, abort, Api, Resource

from views.types import TypesList, Types
from views.services import Services
from views.licenses import Licenses, LicensesList

app = Flask(__name__)

api = Api(app)

api.add_resource(TypesList, '/types')
api.add_resource(Types, '/types/<typeID>')

api.add_resource(Services, '/services')

api.add_resource(Licenses, '/licenses')
api.add_resource(LicensesList, '/licenses/<licenseID>')

if __name__ == '__main__':
    app.run(port=5000, host="0.0.0.0")

