
import sys
import os
import requests
import logging
from datetime import datetime, timedelta
from flask_restful import reqparse, abort, Api, Resource
from flask import request
from flask import jsonify, make_response
from flask import Blueprint

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from settings import *
from db import db_session
from models import Users


github = Blueprint('github', __name__)


@github.route("/auth_callback", methods = ['GET'])
def auth_callback():

    post_data = {"client_id": GITHUB_CLIENT_ID,
                 "client_secret": GITHUB_CLIENT_SECRET,
                 "code": request.args.get("code"),
                 "state": request.args.get("state")
                }
    headers = {"Accept": "application/json"}
    response = requests.post(GITHUB_TOKEN_URL, data=post_data, headers=headers)

    logging.basicConfig(stream=sys.stderr)
    logging.getLogger().setLevel(logging.DEBUG)

    log = logging.getLogger()

    token = response.json()["access_token"]


    response = requests.get(GITHUB_USER_INFO_URL + "?access_token=" + token)

    emails = response.json()

    email = None
    for i in emails:
        if i["primary"] == True and i["verified"] == True:
            email = i["email"]
            break

    if email == None:
        return "ERROR", 500

    user = Users(token, "github", email)

    db_session.add(user)
    db_session.commit()

    return token

