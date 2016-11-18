
from flask_restful import Resource
from flask import request

from licenseManager import db, build_response
from licenseManager.models import License, Type, Service


class TypesList(Resource):

    def get(self):
        state = 'all'
        if 'state' in request.args:
            state = request.args.get('state')

        if state == 'all':
            type = Type.query.all()
        elif state == 'active':
            type = Type.query.filter_by(active=True).all()
        elif state == 'inactive':
            type = Type.query.filter_by(active=False).all()

        return build_response(status_code=200, description="Types list successfully retrieved", data={"types": [o.serialize for o in type]})

    def post(self):
        if 'description' not in request.form or 'duration' not in request.form:
            return build_response(status_code=400, error="Missing fields", description="Missing description or duration argument")

        new_type = Type(request.form['description'], request.form['duration'])
        db.session.add(new_type)
        db.session.commit()

        return build_response(status_code=200, description="Type successfully created", data=new_type.serialize)


class Types(Resource):

    def get(self, typeID):
        type = Type.query.get(typeID)

        if type is None:
            return build_response(status_code=404, error="Invalid TypeID", description="Type ID provided does not exist")

        return build_response(status_code=200, description="Type successfully retrieved", data=type.serialize)

    def delete(self, typeID):
        type = Type.query.get(typeID)

        if type is None:
            return build_response(status_code=404, error="Invalid TypeID", description="Type ID provided does not exist")

        type.active = False
        db.session.commit()

        return build_response(status_code=200, description="Type successfully deleted", data=type.serialize)
