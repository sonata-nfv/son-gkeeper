
from app import db
import uuid
import datetime

class Type(db.Model):
    valid_status = ["ACTIVE", "SUSPENDED"]

    type_uuid = db.Column(db.String, primary_key=True, default=str(uuid.uuid4()))
    description = db.Column(db.String)
    duration = db.Column(db.Integer)
    status = db.Column(db.String, default="ACTIVE")

    def __init__(self, description, duration, status="ACTIVE"):
        self.type_uuid = str(uuid.uuid4())
        self.description = description
        self.duration = duration
        self.status = status

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'type_uuid': self.type_uuid,
            'type': self.description,
            'duration': self.duration,
            'status': self.status
        }


class License(db.Model):
    valid_status = ["ACTIVE", "SUSPENDED", "INACTIVE"]

    type_uuid = db.Column(db.String, db.ForeignKey("type.type_uuid"), nullable=False)
    service_uuid = db.Column(db.String, nullable=False)
    user_uuid = db.Column(db.String, nullable=False)

    license_uuid = db.Column(db.String, primary_key=True, default=str(uuid.uuid4()))
    description = db.Column(db.String)
    startingDate = db.Column(db.DateTime, default=datetime.datetime.now())
    expiringDate = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String, default="ACTIVE")

    def __init__(self, type_uuid, service_uuid, user_uuid, description, startingDate, expiringDate, status="ACTIVE"):
        self.type_uuid = type_uuid
        self.service_uuid = service_uuid
        self.user_uuid = user_uuid
        self.license_uuid = str(uuid.uuid4())
        self.description = description
        self.startingDate = startingDate
        self.expiringDate = expiringDate
        self.status = status

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'license_uuid': self.license_uuid,
            'user_uuid': self.user_uuid,
            'service_uuid': self.service_uuid,
            'description': self.description,
            'startingDate': self.startingDate.strftime('%d-%m-%Y %H:%M'),
            'expiringDate': self.expiringDate.strftime('%d-%m-%Y %H:%M'),
            'status': self.status
        }
