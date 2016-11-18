import os
import sys
import json
import unittest
import xmlrunner
import uuid
from datetime import datetime, timedelta

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from licenseManager import app, db

class TestCase(unittest.TestCase):

    def setUp(self):
        app.config['TESTING'] = True
        # Uncomment and change to use a different database for testing
        #app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql://es:es-test@192.168.0.201:5432/usermanagement"
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

    def test_add_active_service(self):
        # Test adding a active service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]
        service_starting_date = resp_json["data"]["starting_date"]
        service_expiring_date = resp_json["data"]["expiring_date"]
        service_external_service_uuid = resp_json["data"]["external_service_uuid"]
        desc = resp_json["data"]["description"]
        active = resp_json["data"]["active"]

        self.assertEqual(service_starting_date, startingDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(service_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(desc, "Test")
        self.assertEqual(str(external_service_uuid), service_external_service_uuid)
        self.assertTrue(active)

    def test_add_inactive_service(self):
        # Test adding a inactive service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid,
                                                        active=False))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]
        service_starting_date = resp_json["data"]["starting_date"]
        service_expiring_date = resp_json["data"]["expiring_date"]
        service_external_service_uuid = resp_json["data"]["external_service_uuid"]
        desc = resp_json["data"]["description"]
        active = resp_json["data"]["active"]

        self.assertEqual(service_starting_date, startingDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(service_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))
        self.assertEqual(desc, "Test")
        self.assertEqual(str(external_service_uuid), service_external_service_uuid)
        self.assertFalse(active)

    def test_get_service(self):
        # Test getting a list of services

        # First adding a service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Getting the Service list
        response = self.app.get("/api/v1/services/")
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_list = []
        for i in resp_json["data"]["services"]:
            service_list.append(i["service_uuid"])

        self.assertTrue(service_uuid in service_list)

        # Getting the Service by uuid
        response = self.app.get("/api/v1/services/%s/"%service_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)
        self.assertEqual(resp_json["data"]['service_uuid'], service_uuid)

    def test_delete_service(self):
        # Test deleting a service

        # First adding a service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Deleting the service
        response = self.app.delete("/api/v1/services/%s/"%service_uuid)
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        self.assertEqual(resp_json["data"]['service_uuid'], service_uuid)
        self.assertFalse(resp_json["data"]["active"])

        # Deleting already deleted service
        response = self.app.delete("/api/v1/services/%s/"%service_uuid)
        self.assertEqual(response.status_code, 304)

    def test_add_license(self):
        # Test adding a license

        # Adding service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
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

        # Testing adding a license that the same user already has for that service of that type
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
                                                        description="Test",
                                                        startingDate=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        active=True))
        self.assertEqual(response.status_code, 304)

        # Adding initially suspended license
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="bbb-aaa-aaaa-aaa",
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

        # Adding service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
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

        # Adding service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
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
                                                                        user_uuid="aaa-aaa-aaaa-aaa"))

        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        license_license_uuid = resp_json["data"]["license_uuid"]
        license_expiring_date = resp_json["data"]["expiringDate"]
        self.assertEqual(license_uuid, license_license_uuid)
        self.assertEqual(license_expiring_date, expiringDate.strftime('%d-%m-%Y %H:%M'))

    def test_suspend_license(self):
        # Test suspending a license

        # Adding service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
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

        # Adding service
        startingDate = datetime.now()
        expiringDate = startingDate + timedelta(days=60)
        external_service_uuid = uuid.uuid4()
        response = self.app.post("/api/v1/services/", data=dict(description="Test",
                                                        expiring_date= expiringDate.strftime('%d-%m-%Y %H:%M'),
                                                        starting_date=startingDate.strftime('%d-%m-%Y %H:%M'),
                                                        external_service_uuid=external_service_uuid))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        service_uuid = resp_json["data"]["service_uuid"]

        # Adding License Type
        response = self.app.post("/api/v1/types/", data=dict(description="TEST_GET", duration=30))
        self.assertEqual(response.status_code, 200)
        resp_json = json.loads(response.data)

        type_uuid = resp_json["data"]["type_uuid"]

        # Adding active License
        expiringDate = startingDate + timedelta(days=30)
        response = self.app.post("/api/v1/licenses/", data=dict(type_uuid=type_uuid,
                                                        service_uuid=service_uuid,
                                                        user_uuid="aaa-aaa-aaaa-aaa",
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

unittest.main(testRunner=xmlrunner.XMLTestRunner(output='test-reports'))
