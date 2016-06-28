import os
import sys
import unittest
import logging
import json


from flask_testing import TestCase, LiveServerTestCase
from flask_testing.utils import ContextVariableDoesNotExist

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from settings import BASE_DIR
from app import app
import db
type_uuid = None
class TestCase(unittest.TestCase):

    def setUp(self):
        #app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(BASE_DIR, 'test.db')
        app.config['TESTING'] = True
        self.app = app.test_client()
        
        db.init_db()

    def tearDown(self):
        pass

    def test_add_type(self):
        global type_uuid 

        response = self.app.post("/types", data=dict(type="Test", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)
        
        log = logging.getLogger()
        log.debug(response.status_code)
        log.debug(response.data)
        
        type_uuid = resp_json["type_uuid"]
        log.debug(resp_json["type_uuid"])
        duration = resp_json["duration"]
        desc = resp_json["type"]

        self.assertEqual(duration, 30)
        self.assertEqual(desc, "Test")


    def test_get_type(self):

        response = self.app.get("/types")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)
        
        log = logging.getLogger()
        log.debug(response.status_code)

        types_list = []
        for i in resp_json["types"]:
            types_list.append(i["type_uuid"])

        self.assertTrue(type_uuid in types_list)

    def test_delete_type(self):

        response = self.app.delete("/types/" + type_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)
        
        log = logging.getLogger()
        log.debug(response.status_code)

        self.assertFalse(resp_json["active"])


if __name__ == '__main__':
    logging.basicConfig(stream=sys.stderr)
    logging.getLogger().setLevel(logging.DEBUG)
    unittest.main()

