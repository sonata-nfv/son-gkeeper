
import datetime
import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from db import Base


class Type(Base):
    __tablename__ = 'types'

    type_uuid = Column(String, primary_key=True, default=str(uuid.uuid4()))
    type = Column(String)
    duration = Column(Integer)
    active = Column(Boolean, default=True)

    def __init__(self, arg_type, duration):
        self.type_uuid = str(uuid.uuid4())
        self.type = arg_type
        self.duration = duration
        self.active = True

    def __repr__(self):
        return "<License(uuid='%s', type='%s', duration='%s', active='%s')>" % (self.type_uuid, self.type, self.duration, self.active)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'type_uuid': self.type_uuid,
            'type': self.type,
            'duration': self.duration,
            'active': self.active
        }


class License(Base):
    __tablename__ = 'licenses'

    type_uuid = Column(String, ForeignKey("types.type_uuid"), primary_key=True)
    service_uuid = Column(String, ForeignKey('services.service_uuid'), primary_key=True)
    user_uuid = Column(String, primary_key=True)

    license_uuid = Column(String, unique=True, default=str(uuid.uuid4()))
    description = Column(String)
    startingDate = Column(DateTime, default=datetime.datetime.now())
    expiringDate = Column(DateTime, nullable=False)
    active = Column(Boolean, default=True)
    suspended = Column(Boolean, default=False)

    def __init__(self, type_uuid, service_uuid, user_uuid, description, startingDate, expiringDate, active):
        self.type_uuid = type_uuid
        self.service_uuid = service_uuid
        self.user_uuid = user_uuid
        self.license_uuid = str(uuid.uuid4())
        self.description = description
        if not startingDate is None:
            self.startingDate = startingDate
        self.expiringDate = expiringDate
        if not active is None:
            self.active = active
        self.suspended = False

    def __repr__(self):
        return "<License(license_uuid='%s', user_uuid='%s', service_uuid='%s', description='%s', statingDate='%s', expiringDate='%s', \
                                                                                    active='%s', suspended='%s')>" \
               %(self.license_uuid, self.user_uuid, self.service_uuid, self.description, self.startingDate, self.expiringDate, self.active,
            self.suspended)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'license_uuid': self.license_uuid,
            'user_uuid': self.user_uuid,
            'service_uuid': self.service_uuid,
            'description': self.description,
            'startingDate': self.startingDate.strftime('%d-%m-%y %H:%M'),
            'expiringDate': self.expiringDate.strftime('%d-%m-%y %H:%M'),
            'active': self.active,
            'suspended': self.suspended
        }


class Service(Base):
    __tablename__ = 'services'

    service_uuid = Column(String, primary_key=True, default = str(uuid.uuid4()))
    description = Column(String)
    expiringDate = Column(DateTime, nullable=False)
    startingDate = Column(DateTime, nullable=False, default = datetime.datetime.now())
    active = Column(Boolean, default=True)

    def __init__(self, descpt, expDate, startDate, active):
        self.service_uuid = str(uuid.uuid4())
        self.description = descpt
        self.expiringDate = expDate
        if not (active is None):
            self.active = active
        if not (startDate is None):
            self.startingDate = startDate

    def __repr__(self):
        return "<Service(service_uuid='%s', description='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.service_uuid, self.description, self.expiringDate, self.startingDate, self.active)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'service_uuid': self.service_uuid,
            'description': self.description,
            'startingDate': self.startingDate.strftime('%d-%m-%y %H:%M'),
            'expiringDate': self.expiringDate.strftime('%d-%m-%y %H:%M'),
            'active': self.active
        }

