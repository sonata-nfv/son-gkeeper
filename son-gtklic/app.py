
import sys
import os
import json
import unittest
import xmlrunner
import logging

from flask import Flask, Response
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Api
from flask_script import Manager, Server, prompt_bool
from flask_migrate import Migrate, MigrateCommand

app = Flask(__name__)

app.config.from_pyfile('settings.py')

logger = logging.getLogger('werkzeug')
handler = logging.FileHandler(app.config["LOG_FILE"])
logger.addHandler(handler)
app.logger.addHandler(handler)

db = SQLAlchemy(app)
migrate = Migrate(app, db)

manager = Manager(app)
manager.add_command('db', MigrateCommand)
manager.add_command("runserver", Server(port=app.config["PORT"]))

@manager.command
def dropdb():
    if prompt_bool(
        "Are you sure you want to lose all your data?"):
        db.drop_all()

# Method used to unify responses sintax
def build_response(status_code, description="", error="", data=""):
    jd = {"status_code" : status_code, "error": error, "description": description, "data": data}
    resp = Response(response=json.dumps(jd), status=status_code, mimetype="application/json")
    return resp


from routes.licenses import *

api = Api(app)

api.add_resource(LicensesList, '/api/v1/licenses/')
api.add_resource(Licenses, '/api/v1/licenses/<licenseID>/')
