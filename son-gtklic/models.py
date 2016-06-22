
import datetime
import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from db import Base


class Type(Base):
    __tablename__ = 'types'

    type_uuid = Column(String, primary_key=True, default=str(uuid.uuid4()))
    type = Column(String)
    active = Column(Boolean, default=True)

    def __init__(self, arg_type):
        self.type_uuid = str(uuid.uuid4())
        self.type = arg_type
        self.active = True

    def __repr__(self):
        return "<License(uuid='%s', type='%s', active='%s')>" % (self.type_uuid, self.type, self.active)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'type_uuid': self.type_uuid,
            'type': self.type,
            'active': self.active
        }

class License(Base):
    __tablename__ = 'licenses'

    license_uuid = Column(String, primary_key=True, default=uuid.uuid4())
    user_uuid = Column(String)
    description = Column(String)
    startingDate = Column(DateTime, default=datetime.datetime.now())
    expiringDate = Column(DateTime, nullable=False)
    active = Column(Boolean, default=True)
    suspended = Column(Boolean, default=False)
    type = Column(String, ForeignKey("types.type_uuid"), nullable=False)

    def __repr__(self):
        return "<License(license_uuid='%s', user_uuid='%s', description='%s', statingDate='%s', expiringDate='%s', \
                                                                                    active='%s', suspended='%s')>" \
               %(self.license_uuid, self.user_uuid, self.description, self.startingDate, self.expiringDate, self.active,
            self.suspended)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'license_uuid': self.license_uuid,
            'user_uuid': self.user_uuid,
            'description': self.description,
            'startingDate': self.startingDate,
            'expiringDate': self.expiringDate,
            'active': self.active,
            'suspended': self.suspended
        }


class Service(Base):
    __tablename__ = 'services'

    service_uuid = Column(String, primary_key=True, default = uuid.uuid4())
    description = Column(String)
    expiringDate = Column(DateTime, nullable=False)
    startingDate = Column(DateTime, nullable=False, default = datetime.datetime.now())
    active = Column(Boolean, default=True)

    def __repr__(self):
        return "<Service(service_uuid='%s', description='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.service_uuid, self.description, self.expiringDate, self.startingDate, self.active)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'service_uuid': self.service_uuid,
            'description': self.description,
            'startingDate': self.startingDate,
            'expiringDate': self.expiringDate,
            'active': self.active
        }


class Purchase(Base):
    __tablename__ = 'purchases'

    uuid_service = Column(String, ForeignKey('services.service_uuid'), primary_key=True)
    uuid_license = Column(String, ForeignKey('licenses.license_uuid'), primary_key=True)

    def __repr__(self):
        return "<Purchase(uuid_service='%s', uuid_license='%s')>" % (
            self.uuid_service, self.uuid_license)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'uuid_service': self.uuid_service,
            'uuid_license': self.uuid_license,
        }
