
import sys
import os
import json
import unittest
import xmlrunner

from flask import Flask, Response
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Api
from flask_script import Manager, Server, prompt_bool
from flask_migrate import Migrate, MigrateCommand

app = Flask(__name__)

app.config.from_pyfile('settings.py')


db = SQLAlchemy(app)
migrate = Migrate(app, db)

manager = Manager(app)
manager.add_command('db', MigrateCommand)
manager.add_command("runserver", Server())

@manager.command
def dropdb():
    if prompt_bool(
        "Are you sure you want to lose all your data?"):
        db.drop_all()

# Method used to unify responses sintax
def build_response(status_code, description="", error="", data=""):
    jd = {"status_code:" : status_code, "error": error, "description": description, "data": data}
    resp = Response(response=json.dumps(jd), status=status_code, mimetype="application/json")
    return resp


from routes.licenses import *
from routes.services import *
from routes.types import *

api = Api(app)

api.add_resource(TypesList, '/api/v1/types/')
api.add_resource(Types, '/api/v1/types/<typeID>/')

api.add_resource(ServicesList, '/api/v1/services/')
api.add_resource(Services, '/api/v1/services/<serviceID>/')

api.add_resource(LicensesList, '/api/v1/licenses/')
api.add_resource(Licenses, '/api/v1/licenses/<licenseID>/')
