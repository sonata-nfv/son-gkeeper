
import datetime
import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from db import Base


class Users(Base):
    __tablename__ = 'users'

    user_uuid = Column(String, primary_key=True, default=str(uuid.uuid4()))
    access_token = Column(String)
    platform = Column(String)
    email = Column(String)

    def __init__(self, access_token, platform, email):
        self.user_uuid = str(uuid.uuid4())
        self.access_token = access_token
        self.platform = platform
        self.email = email

    def __repr__(self):
        return "<GitHub(uuid='%s', access_token='%s', platform='%s', email='%s')>" % (self.user_uuid, self.access_token, self.platform, self.email)

    @property
    def serialize(self):
        """Return object data in easily serializeable format"""
        return {
            'user_uuid': self.user_uuid,
            'access_token': self.access_token,
            'platform': self.platform,
            'email': self.email
        }



