
import settings
import datetime
import uuid
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import UUID

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = settings.SQL_CONNECTION
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Type(db.Model):
    __tablename__ = 'types'

    type_uuid = db.Column(UUID(), primary_key=True, default=uuid.uuid4())
    description = db.Column(db.String)
    active = db.Column(db.Boolean, default=True)

    def __repr__(self):
        return "<License(uuid='%s', description='%s')>" % (self.type_uuid, self.description)

class License(db.Model):
    __tablename__ = 'licenses'

    license_uuid = db.Column(UUID(), primary_key=True, default=uuid.uuid4())
    description = db.Column(db.String)
    startingDate = db.Column(db.DateTime, default=datetime.datetime.now())
    expiringDate = db.Column(db.DateTime, nullable=False)
    active = db.Column(db.Boolean, default=True)
    suspended = db.Column(db.Boolean, default=False)
    type = db.Column(UUID(), db.ForeignKey("types.type_uuid"), nullable=False)

    def __repr__(self):
        return "<License(uuid='%s', description='%s', statingDate='%s', expiringDate='%s')>" % (
            self.license_uuid, self.description, self.startingDate, self.expiringDate)


class Service(db.Model):
    __tablename__ = 'services'

    service_uuid = db.Column(UUID(), primary_key=True, default = uuid.uuid4())
    description = db.Column(db.String)
    expiringDate = db.Column(db.DateTime, nullable=False)
    startingDate = db.Column(db.DateTime, nullable=False, default = datetime.datetime.now())
    active = db.Column(db.Boolean, default=True)

    purchases = db.relationship("purchases")

    def __repr__(self):
        return "<Service(service_uuid='%s', description='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.service_uuid, self.description, self.expiringDate, self.startingDate, self.active)


class Purchase(db.Model):
    __tablename__ = 'purchases'

    uuid_user = db.Column(UUID(), primary_key=True)
    uuid_service = db.Column(UUID(), db.ForeignKey('licenses.license_uuid'), primary_key=True)
    uuid_license = db.Column(UUID(), db.ForeignKey('services.service_uuid'), primary_key=True)
    expiringDate = db.Column(db.DateTime, nullable=False)
    startingDate = db.Column(db.DateTime, nullable=False)
    active = db.Column(db.Boolean, default=True)

    def __repr__(self):
        return "<Purchase(uuid_user='%s', uuid_service='%s', uuid_license='%s', expiringDate='%s', startingDate='%s', active='%s')>" % (
            self.uuid_user, self.uuid_service, self.uuid_license, self.expiringDate, self.startingDate, self.active)



db.create_all()
db.session.commit()

print "Successfully Created..."
