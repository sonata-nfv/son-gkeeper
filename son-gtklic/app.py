
from flask import Flask
from flask_restful import reqparse, abort, Api, Resource
from views.types import TypesList, Types

app = Flask(__name__)

api = Api(app)

api.add_resource(TypesList, '/types')
api.add_resource(Types, '/types/<typeID>')


if __name__ == '__main__':
    app.run(port=5000, host="0.0.0.0")

