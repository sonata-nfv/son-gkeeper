
import sys
import os
import datetime
from flask_restful import reqparse, abort, Api, Resource
from flask import request, make_response
from flask import jsonify

from licenseManager.models import License, Type, Service
from licenseManager import db, build_response


class Services(Resource):

    def get(self, serviceID):
        service = Service.query.get(serviceID)
        return build_response(status_code=200, description="Service successfully retrieved", data=service.serialize)

    def put(self, serviceID):
        service = Service.query.get(serviceID)
        if 'expiringDate' not in request.form:
            return build_response(status_code=400, error="Missing fields", description="Missing expiringDate argument")
        try:
            service.expiringDate = datetime.datetime.strptime(str(request.form.get('startingDate')),"%d-%m-%Y %H:%M")
        except:
            return build_response(status_code=400, error="Invalid date format", description="ExpiringDate is in the wrong format")
        db.session.commit()
        return build_response(status_code=200, description="Service successfully renewed", data=service.serialize)

    def delete(self, serviceID):
        service = Service.query.get(serviceID)

        if service is None:
            return build_response(status_code=404, error="Invalid ServiceID", description="Service ID provided does not exist")

        if service.active is False:
            return build_response(status_code=304, data=service.serialize, description="Service ID was already deleted")

        service.active = False
        db.session.commit()

        return build_response(status_code=200, data=service.serialize, description="Service ID was successfully deleted")


class ServicesList(Resource):

    def get(self):
        service = Service.query.all()
        return build_response(status_code=200, data={"services": [o.serialize for o in service]}, description="Service list successfully retrieved")

    def post(self):
        try:
            if 'description' not in request.form or 'expiring_date' not in request.form or 'external_service_uuid' not in request.form:
                return build_response(status_code=400, error="Missing fields", description="Missing description, Expiring Date or External Service Uuid argument")

            startingDate = datetime.datetime.now()
            if 'starting_date' in request.form:
                startingDate = datetime.datetime.strptime(str(request.form.get('starting_date')),"%d-%m-%Y %H:%M")

            new_service = Service(request.form['description'],
                    datetime.datetime.strptime(str(request.form['expiring_date']),"%d-%m-%Y %H:%M"),
                    request.form['external_service_uuid'],
                    startingDate,
                    request.form.get('active'))
        except:
            return build_response(status_code=400, error="Invalid date format", description="StartingDate or ExpiringDate is in the wrong format")

        db.session.add(new_service)
        db.session.commit()

        return build_response(status_code=200, data=new_service.serialize, description="Service ID was successfully created")
