
import sys
import os
import datetime
from flask_restful import reqparse, abort, Api, Resource
from flask import request, make_response
from flask import jsonify

sys.path.insert(1, os.path.join(sys.path[0], '..'))

from models import Service
from db import db_session


class Services(Resource):

    def get(self):
        service = Service.query.all()

        return jsonify({"services": [o.serialize for o in service]})


    def post(self):
        
        try:
            startingDate = datetime.datetime.now()
            if not (request.form.get('startingDate') is None):
                startingDate = datetime.datetime.strptime(str(request.form.get('startingDate')),"%d-%m-%y %H:%M")

            new_service = Service(request.form['description'], 
                    datetime.datetime.strptime(str(request.form['expiringDate']),"%d-%m-%y %H:%M"), 
                    startingDate, 
                    request.form.get('active'))
        except:
            return "Invalid date format", 406
        

        db_session.add(new_service)
        db_session.commit()

        return jsonify(new_service.serialize)

    def delete(self):
        service = Service.query.filter_by(service_uuid=request.form.get('active')).first()

        if service is None:
            return "Service ID not found", 404

        if service.active is False:
            
            return make_response(jsonify(service.serialize), 304)

        service.active = False
        db_session.commit()

        return jsonify(service.serialize)
