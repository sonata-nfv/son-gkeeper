import os
import sys
import logging
import json
import unittest
import xmlrunner

from datetime import datetime, timedelta

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from app import app
import db


class TestCase(unittest.TestCase):

    def setUp(self):
        app.config['TESTING'] = True
        self.app = app.test_client()
        db.init_db()

    def tearDown(self):
        pass


if __name__ == '__main__':
    logging.basicConfig(stream=sys.stderr)
    logging.getLogger().setLevel(logging.DEBUG)
    unittest.main(testRunner=xmlrunner.XMLTestRunner(output='test-reports'))
