
import sys
import os
import urllib
import uuid
from flask_restful import reqparse, abort, Api, Resource
from flask import request, render_template, redirect
from flask import jsonify
from flask import Blueprint

sys.path.insert(1, os.path.join(sys.path[0], '..'))

import settings
from db import db_session


authorization = Blueprint('authorization', __name__)


@authorization.route("/authorize", methods = ['GET'])
def init_authorize():
    return render_template('login_selector.html')

@authorization.route("/authorize", methods = ['POST'])
def authorize_url():
    platform = request.form['platform']

    if platform == "github":
        state = str(uuid.uuid4())
        params = {  "client_id": settings.GITHUB_CLIENT_ID,
                    "state": state,
                    "scope": "user"
                    }

        url = settings.GITHUB_AUTH_URL+ "?" +urllib.urlencode(params)
        return redirect(url, code=200)

    return "ERROR", 200

