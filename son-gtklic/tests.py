import os
import sys
import json
import unittest
import xmlrunner
import uuid
from datetime import datetime, timedelta

from app import app, db

class TestCase(unittest.TestCase):

    def setUp(self):
        app.config['TESTING'] = True
        # Uncomment and change to use a different database for testing
        #app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql://user:password@db_ip:5432/db_name"
        self.app = app.test_client()
        db.create_all()

    def tearDown(self):
        db.session.remove()
        db.drop_all()

    def test_add_type(self):
        # Test adding a license type

        response = self.app.post("/api/v1/types/", data=dict(description="Test", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]
        duration = resp_json["data"]["duration"]
        desc = resp_json["data"]["type"]

        self.assertEqual(duration, 30)
        self.assertEqual(desc, "Test")

    def test_get_types(self):
        # Test getting a license type in the list of all

        # First Adding a type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Get all license types
        response = self.app.get("/api/v1/types/")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        types_list = []
        for i in resp_json["data"]["types"]:
            types_list.append(i["type_uuid"])

        self.assertTrue(type_uuid in types_list)

        # Get a specific license types
        response = self.app.get("/api/v1/types/%s/" % type_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(resp_json["data"]["type_uuid"], type_uuid)

    def test_delete_type(self):
        # Test deleting (desactivating) a license type

        # First Adding a type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_DELETE", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        response = self.app.delete("/api/v1/types/%s/" % type_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(resp_json["data"]["type_uuid"], type_uuid)
        self.assertFalse(resp_json["data"]["active"])

    def test_add_license(self):
        # Test adding a license

        service_uuid = uuid.uuid4()
        user_uuid = uuid.uuid4()
        startingDate = datetime.now()

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]
        license_expiring_date = resp_json["data"]["expiringDate"]
        desc = resp_json["data"]["description"]
        suspended = resp_json["data"]["suspended"]

        self.assertEqual(license_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(desc, "Test")
        self.assertFalse(suspended)

        # Testing adding a license that the same user already has for a service of that type
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 304)

        # New user for Testing
        user_uuid = uuid.uuid4()

        # Adding initially suspended license
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=False))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]
        license_expiring_date = resp_json["data"]["expiringDate"]
        desc = resp_json["data"]["description"]
        suspended = resp_json["data"]["suspended"]

        self.assertEqual(license_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(desc, "Test")
        self.assertTrue(suspended)

    def test_get_license(self):
        # Test getting a license

        service_uuid = uuid.uuid4()
        user_uuid = uuid.uuid4()
        startingDate = datetime.now()

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]

        # Test get all licenses
        response = self.app.get("/api/v1/licenses/")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_list = []
        for i in resp_json["data"]["licenses"]:
            license_list.append(i["license_uuid"])

        self.assertTrue(license_uuid in license_list)

        # Test get a specific license if is valid
        response = self.app.get("/api/v1/licenses/%s/"%license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(license_uuid, resp_json["data"]["license_uuid"])

        # Test if a license is valid
        response = self.app.head("/api/v1/licenses/%s/"%license_uuid)
        self.assertEqual(response.status_code, 200)

    def test_renew_license(self):
        # Test renewing a license

        service_uuid = uuid.uuid4()
        user_uuid = uuid.uuid4()
        startingDate = datetime.now()

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]
        license_expiring_date = resp_json["data"]["expiringDate"]
        self.assertEqual(license_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))

        # Renewing a License
        expiringDate = expiringDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/%s/"%license_uuid, data=dict(
                                                                        type_uuid=type_uuid,
                                                                        user_uuid=user_uuid))

        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_license_uuid = resp_json["data"]["license_uuid"]
        license_expiring_date = resp_json["data"]["expiringDate"]
        self.assertEqual(license_uuid, license_license_uuid)
        self.assertEqual(license_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))

    def test_suspend_license(self):
        # Test suspending a license

        service_uuid = uuid.uuid4()
        user_uuid = uuid.uuid4()
        startingDate = datetime.now()

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]

        # Suspend a license
        response = self.app.put("/api/v1/licenses/%s/"%license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(license_uuid, resp_json["data"]["license_uuid"])
        self.assertTrue(resp_json["data"]["suspended"])

    def test_cancel_license(self):
        # Test canceling a license

        service_uuid = uuid.uuid4()
        user_uuid = uuid.uuid4()
        startingDate = datetime.now()

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid=user_uuid,
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_uuid = resp_json["data"]["license_uuid"]

        # Suspend a license
        response = self.app.delete("/api/v1/licenses/%s/"%license_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(license_uuid, resp_json["data"]["license_uuid"])
        self.assertFalse(resp_json["data"]["active"])


if __name__ == '__main__':
    unittest.main(testRunner=xmlrunner.XMLTestRunner(output='test-reports'))
