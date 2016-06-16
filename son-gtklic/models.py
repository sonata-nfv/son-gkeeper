
import datetime
import uuid
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
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
        return "<License(uuid='%s', description='%s')>" % (self.type_uuid, self.description)

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
    description = Column(String)
    startingDate = Column(DateTime, default=datetime.datetime.now())
    expiringDate = Column(DateTime, nullable=False)
    active = Column(Boolean, default=True)
    suspended = Column(Boolean, default=False)
    type = Column(String, ForeignKey("types.type_uuid"), nullable=False)

    def __repr__(self):
        return "<License(uuid='%s', description='%s', statingDate='%s', expiringDate='%s')>" % (
            self.license_uuid, self.description, self.startingDate, self.expiringDate)


class Service(Base):
    __tablename__ = 'services'

    service_uuid = Column(String, primary_key=True, default = uuid.uuid4())
    description = Column(String)
    expiringDate = Column(DateTime, nullable=False)
    startingDate = Column(DateTime, nullable=False, default = datetime.datetime.now())
    active = Column(Boolean, default=True)

    #purchases = relationship("Purchases")

    def __repr__(self):
        return "<Service(service_uuid='%s', description='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.service_uuid, self.description, self.expiringDate, self.startingDate, self.active)


class Purchase(Base):
    __tablename__ = 'purchases'

    uuid_user = Column(String, primary_key=True)
    uuid_service = Column(String, ForeignKey('services.service_uuid'), primary_key=True)
    uuid_license = Column(String, ForeignKey('licenses.license_uuid'), primary_key=True)
    expiringDate = Column(DateTime, nullable=False)
    startingDate = Column(DateTime, nullable=False)
    active = Column(Boolean, default=True)

    #service = relationship("Service")

    def __repr__(self):
        return "<Purchase(uuid_user='%s', uuid_service='%s', uuid_license='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.uuid_user, self.uuid_service, self.uuid_license, self.expiringDate, self.startingDate, self.active)
