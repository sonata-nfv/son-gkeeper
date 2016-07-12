
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



