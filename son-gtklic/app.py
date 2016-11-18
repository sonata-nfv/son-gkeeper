
import settings
from flask import Flask
from flask_restful import reqparse, abort, Api, Resource

from views.types import TypesList, Types
from views.services import Services, ServicesList
from views.licenses import Licenses, LicensesList

app = Flask(__name__)

api = Api(app)

api.add_resource(TypesList, '/types')
api.add_resource(Types, '/types/<typeID>')

api.add_resource(ServicesList, '/services')
api.add_resource(Services, '/services/<serviceID>')

api.add_resource(LicensesList, '/licenses')
api.add_resource(Licenses, '/licenses/<licenseID>')

if __name__ == '__main__':
    app.run(port=settings.PORT, host=settings.HOST)

