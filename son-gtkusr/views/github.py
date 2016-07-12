
import sys
import os
from datetime import datetime, timedelta
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify, make_response
from flask import Blueprint

sys.path.insert(1, os.path.join(sys.path[0], '..'))


from db import db_session


github = Blueprint('github', __name__)


@github.route("/auth_callback")
def auth_callback():
    return request.args.get('code'), 200
