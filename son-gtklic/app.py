
import settings
import datetime
import uuid
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import UUID
from flask_restful import reqparse, abort, Api, Resource
from views.types import TypesList, Types

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = settings.SQL_CONNECTION
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
api = Api(app)

api.add_resource(TypesList, '/types')
api.add_resource(Types, '/types/<typeID>')


if __name__ == '__main__':
    app.run(debug=True, port=5000, host="0.0.0.0")

