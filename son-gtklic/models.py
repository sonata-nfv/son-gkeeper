
from app import db
import uuid
import datetime

class Type(db.Model):

    type_uuid = db.Column(db.String, primary_key=True, default=str(uuid.uuid4()))
    description = db.Column(db.String)
    duration = db.Column(db.Integer)
    active = db.Column(db.Boolean, default=True)

    def __init__(self, description, duration):
        self.type_uuid = str(uuid.uuid4())
        self.description = description
        self.duration = duration
        self.active = True

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'type_uuid': self.type_uuid,
            'type': self.description,
            'duration': self.duration,
            'active': self.active
        }


class License(db.Model):

    type_uuid = db.Column(db.String, db.ForeignKey("type.type_uuid"), nullable=False)
    service_uuid = db.Column(db.String, db.ForeignKey('service.service_uuid'), nullable=False)
    user_uuid = db.Column(db.String, nullable=False)

    license_uuid = db.Column(db.String, primary_key=True, default=str(uuid.uuid4()))
    description = db.Column(db.String)
    startingDate = db.Column(db.DateTime, default=datetime.datetime.now())
    expiringDate = db.Column(db.DateTime, nullable=False)
    active = db.Column(db.Boolean, default=True)
    suspended = db.Column(db.Boolean, default=False)

    def __init__(self, type_uuid, service_uuid, user_uuid, description, startingDate, expiringDate, suspended=False, active=None):
        self.type_uuid = type_uuid
        self.service_uuid = service_uuid
        self.user_uuid = user_uuid
        self.license_uuid = str(uuid.uuid4())
        self.description = description
        self.startingDate = startingDate
        self.expiringDate = expiringDate
        if not active is None:
            self.active = active
        self.suspended = suspended

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
            'active': self.active,
            'suspended': self.suspended
        }


class Service(db.Model):

    service_uuid = db.Column(db.String, primary_key=True, default = str(uuid.uuid4()))
    description = db.Column(db.String)
    expiringDate = db.Column(db.DateTime, nullable=False)
    startingDate = db.Column(db.DateTime, nullable=False, default = datetime.datetime.now())
    external_service_uuid = db.Column(db.String, unique=True)
    active = db.Column(db.Boolean, default=True)

    def __init__(self, descpt, expDate, extuid, startDate=None, active=None):
        self.service_uuid = str(uuid.uuid4())
        self.description = descpt
        self.expiringDate = expDate
        self.external_service_uuid = extuid
        if not (active is None):
            self.active = active
        if not (startDate is None):
            self.startingDate = startDate


    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'service_uuid': self.service_uuid,
            'description': self.description,
            'starting_date': self.startingDate.strftime('%d-%m-%Y %H:%M'),
            'expiring_date': self.expiringDate.strftime('%d-%m-%Y %H:%M'),
            'external_service_uuid': self.external_service_uuid,
            'active': self.active
        }
