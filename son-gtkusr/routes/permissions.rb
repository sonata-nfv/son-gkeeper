##
## Copyright (c) 2015 SONATA-NFV
## ALL RIGHTS RESERVED.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Neither the name of the SONATA-NFV
## nor the names of its contributors may be used to endorse or promote
## products derived from this software without specific prior written
## permission.
##
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the SONATA
## partner consortium (www.sonata-nfv.eu).

require 'json'
require 'sinatra'
require 'net/http'
require_relative '../helpers/init'

#Comment about ROLES
=begin
Large number of roles approach will quickly become unmanageable and it
may be better of using an ACL or something in the application itself.

It is more often implemented as ACLs rather than RBAC.
RBAC is usually used for things like 'manager' has read/write access to a
group of resources, rather than 'user-a' has read access to 'resource-a'.
=end

# Adapter-Keycloak API class
class Keycloak < Sinatra::Application
  # Routes for management operations of resources and associated permissions

  get '/resources/?' do
    logger.debug 'Adapter: entered GET /resources'
    # Return if Authorization is invalid
    #halt 400 unless request.env["HTTP_AUTHORIZATION"]
    #user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    #unless user_token
    #  json_error(400, 'Access token is not provided')
    #end
    #res = token_expired?(user_token)
    #if res != 200
    #  json_error(401, res)
    #end

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT

    keyed_params = keyed_hash(params)
    headers = {'Accept' => 'application/json', 'Content-Type' => 'application/json'}
    headers[:params] = params unless params.empty?

    # Get rid of :offset and :limit
    [:offset, :limit].each { |k| keyed_params.delete(k) }

    # Do the query
    resource_data = Sp_resource.where(keyed_params)

    if resource_data && resource_data.size.to_i > 0
      logger.info "Adapter: leaving GET /resources?#{query_string} with #{resource_data}"
      resource_data = resource_data.paginate(offset: params[:offset], limit: params[:limit])
    else
      logger.info "Adapter: leaving GET /resources?#{query_string} with no resources found"
      # We could not find the resource you are looking for
    end

    response = resource_data.to_json
    halt 200, {'Content-Type' => 'application/json'}, response
  end

  post '/resources' do
    logger.debug 'Adapter: entered POST /resources'
    # Return if Authorization is invalid
    #halt 400 unless request.env["HTTP_AUTHORIZATION"]
    #user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    #unless user_token
    #  json_error(400, 'Access token is not provided')
    #end
    #res = token_expired?(user_token)
    #if res != 200
    #  json_error(401, res)
    #end

    json_error(415, 'Only "Content-type: application/json" is supported') unless
        request.content_type == 'application/json'

    # Compatibility support for JSON content-type
    # Parses and validates JSON format
    form, errors = parse_json(request.body.read)
    halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors

    # JSON form evaluation processes
    unless form.key?('enabled')
      form = form.merge({'enabled'=> true})
    end

    # Check if resource already exists in the database
    begin
      user = Sp_resource.find_by({'username' => form['resource_owner_name']})
      json_error 409, 'Duplicated username'
    rescue Mongoid::Errors::DocumentNotFound => e
      # Continue
    end
    # Check if user ID already exists in the database
    begin
      user = Sp_user.find_by({ '_id' => user_id })
      json_error 409, 'Duplicated user ID'
    rescue Mongoid::Errors::DocumentNotFound => e
      # Continue
    end

    # Save new resource to DB
    begin
      new_user = {}
      new_user['_id'] = user_id
      new_user['username'] = form['username']
      new_user['public_key'] = pkey
      new_user['certificate'] = cert
      user = Sp_user.create!(new_user)
    rescue Moped::Errors::OperationFailure => e
      delete_user(form['username'])
      json_error 409, 'Duplicated user ID' if e.message.include? 'E11000'
    end

    logger.debug "Database: New user #{form['username']} with ID #{user_id} has been added"

    logger.info "New user #{form['username']} has been registered"
    response = {'username' => form['username'], 'userId' => user_id.to_s}
    halt 201, {'Content-type' => 'application/json'}, response.to_json
  end

  put '/resources' do
    logger.debug 'Adapter: entered PUT /resources'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]
    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      json_error(400, 'Access token is not provided')
    end
    res = token_expired?(user_token)
    if res != 200
      json_error(401, res)
    end
  end

  delete '/resources' do
    logger.debug 'Adapter: entered DELETE /resources'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]
    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      json_error(400, 'Access token is not provided')
    end
    res = token_expired?(user_token)
    if res != 200
      json_error(401, res)
    end
  end
end