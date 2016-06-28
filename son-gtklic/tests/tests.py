import os
import sys
import unittest
import logging


from flask_testing import TestCase, LiveServerTestCase
from flask_testing.utils import ContextVariableDoesNotExist

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from settings import BASE_DIR
from app import app
import db

class TestCase(unittest.TestCase):

    def setUp(self):
        #app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(BASE_DIR, 'test.db')
        app.config['TESTING'] = True
        self.app = app.test_client()
        db.init_db()

    def tearDown(self):
        pass

    def test_assert_200(self):
        #log = logging.getLogger("SomeTest.testSomething")
        response = self.app.get("/types")
        #log.debug(dir(response))
        #log.debug(response.status_code)
        self.assertEqual(response.status_code, 200)


if __name__ == '__main__':
    #logging.basicConfig(stream=sys.stderr)
    #logging.getLogger("SomeTest.testSomething").setLevel(logging.DEBUG)
    unittest.main()
