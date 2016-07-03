import os
import sys
import unittest
import logging
import json
from datetime import datetime, timedelta

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from app import app
import db


type_uuid = None
service_uuid = None
license_uuid = None

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

        type_uuid = resp_json["type_uuid"]
        duration = resp_json["duration"]
        desc = resp_json["type"]

        self.assertEqual(duration, 30)
        self.assertEqual(desc, "Test")

    def test_get_type(self):

        response = self.app.get("/types")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        types_list = []
        for i in resp_json["types"]:
            types_list.append(i["type_uuid"])

        self.assertTrue(type_uuid in types_list)

    def test_delete_type(self):

        response = self.app.delete("/types/" + type_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertFalse(resp_json["active"])

    def test_add_service(self):
        global service_uuid

        response = self.app.post("/services", data=dict(description="Test",
                                                        expiringDate="03-07-20 13:46",
                                                        startingDate="22-06-16 13:46",
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["service_uuid"]
        expiringDate = resp_json["expiringDate"]
        desc = resp_json["description"]

        self.assertEqual(expiringDate, "03-07-20 13:46")
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

    def test_zadd_license(self):
        global license_uuid

        response = self.app.post("/licenses", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
                                                        description="Test",
                                                        startingDate="30-06-16 13:46",
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["license_uuid"]
        expiringDate = resp_json["expiringDate"]
        desc = resp_json["description"]

        self.assertEqual(expiringDate, "30-07-16 13:46")
        self.assertEqual(desc, "Test")

    def test_zget_license(self):

        response = self.app.get("/licenses", query_string="user_uuid=aaa-aaa-aaaa-aaa")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_list = []
        for i in resp_json["licenses"]:
            license_list.append(i["license_uuid"])

        self.assertTrue(license_uuid in license_list)

    def test_zcheck_license_valid_get(self):

        response = self.app.get("/licenses/" + license_uuid, query_string="user_uuid=aaa-aaa-aaaa-aaa")
        resp_json = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(resp_json["license_uuid"], license_uuid)

    def test_zcheck_license_valid_head(self):

        response = self.app.head("/licenses/" + license_uuid, query_string="user_uuid=aaa-aaa-aaaa-aaa")
        self.assertEqual(response.status_code, 200)

    def test_zrenew_license(self):

        response = self.app.get("/licenses/" + license_uuid, query_string="user_uuid=aaa-aaa-aaaa-aaa")
        resp_json = json.loads(response.data)
        expiringDate = datetime.strptime(str(resp_json["expiringDate"]), "%d-%m-%y %H:%M")

        response = self.app.post("/licenses/" + license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(datetime.strptime(str(resp_json["expiringDate"]), "%d-%m-%y %H:%M"),
                         expiringDate + timedelta(days=30))

    def test_zsuspend_license(self):

        response = self.app.put("/licenses/" + license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertTrue(resp_json["suspended"])

    def test_zcancel_license(self):

        response = self.app.delete("/licenses/" + license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertFalse(resp_json["active"])

if __name__ == '__main__':
    logging.basicConfig(stream=sys.stderr)
    logging.getLogger().setLevel(logging.DEBUG)
    unittest.main(verbosity=2)

