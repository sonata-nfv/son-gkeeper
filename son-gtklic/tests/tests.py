import os
import sys
import unittest
import logging
import json

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from app import app
import db


type_uuid = None
service_uuid = None


class TestCase(unittest.TestCase):

    def setUp(self):
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

    def test_add_service(self):
        global service_uuid

        response = self.app.post("/services", data=dict(description="Test",
                                                        expiringDate="22-07-20 13:46",
                                                        startingDate="03-07-20 13:46",
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["service_uuid"]
        expiringDate = resp_json["expiringDate"]
        desc = resp_json["description"]

        self.assertEqual(expiringDate, "22-07-20 13:46")
        self.assertEqual(desc, "Test")

    def test_get_service(self):

        response = self.app.get("/services")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_list = []
        for i in resp_json["services"]:
            service_list.append(i["service_uuid"])

        self.assertTrue(service_uuid in service_list)

    def test_delete_service(self):

        response = self.app.delete("/services", data=dict(service_uuid=service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertFalse(resp_json["active"])


if __name__ == '__main__':
    logging.basicConfig(stream=sys.stderr)
    logging.getLogger().setLevel(logging.DEBUG)
    unittest.main()

