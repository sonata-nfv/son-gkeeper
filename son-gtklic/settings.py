import os

POSTGRES_PASSWORD = os.environ.get('POSTGRES_PASSWORD') or 'sonata'
POSTGRES_USER = os.environ.get('POSTGRES_USER') or 'sonata'
POSTGRES_DB = os.environ.get('POSTGRES_DB') or 'licensemanager'
DATABASE_HOST = os.environ.get('DATABASE_HOST') or '192.168.54.249'
DATABASE_PORT = os.environ.get('DATABASE_PORT') or '5432'
PORT = os.environ.get('DATABASE_HOST') or '5000'

SQLALCHEMY_DATABASE_URI = ('postgresql://%s:%s@%s:%s/%s' %(POSTGRES_USER, POSTGRES_PASSWORD, DATABASE_HOST, DATABASE_PORT, POSTGRES_DB))
SQLALCHEMY_TRACK_MODIFICATIONS = True

DEBUG = False

#HOST = "0.0.0.0"
#PORT = 5000
