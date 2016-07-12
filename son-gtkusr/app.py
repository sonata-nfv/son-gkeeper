
import settings
from flask import Flask
from flask_restful import reqparse, abort, Api, Resource

from views.github import github

app = Flask(__name__)

app.register_blueprint(github, url_prefix='/github')

if __name__ == '__main__':
    app.run(port=settings.PORT, host=settings.HOST)

