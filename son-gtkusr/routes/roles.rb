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

# Adapter-Keycloak API class
class Keycloak < Sinatra::Application
  # Get a role by query
  get '/roles/?' do
    #TODO: QUERIES NOT SUPPORTED -> Check alternatives!!
    # This endpoint allows queries for the next fields:
    # search, lastName, firstName, email, username, first, max
    logger.debug 'Adapter: entered GET /roles'
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(search id name description first max)
    keyed_params = keyed_hash(params)
    keyed_params.each { |k, v|
      unless queriables.include? k
        json_error(400, 'Bad query')
      end
    }
    code, realm_roles = get_realm_roles(keyed_params)

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT
    realm_roles = apply_limit_and_offset(JSON.parse(realm_roles), offset=params[:offset], limit=params[:limit])
    halt code.to_i, {'Content-type' => 'application/json'}, realm_roles.to_json
  end

  post '/roles/new/?' do
    # POST /admin/realms/{realm}/roles
    # BodyParameter
    logger.debug 'Adapter: entered POST /roles'
    logger.info "Content-Type is " + request.media_type
    halt 415 unless (request.content_type == 'application/json')

    form, errors = parse_json(request.body.read)
    halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors
    halt 400 unless form.is_a?(Hash)
    #json_error 400, 'Usertype not provided' unless form.key?('userType')
  end

  # Update a role by name
  put '/roles/?' do
    # PUT /admin/realms/{realm}/roles/{id}
    # BodyParameter

  end
  # Delete a role by name
  delete '/roles/?' do
    logger.debug 'Adapter: entered DELETE /roles'
    # DELETE /admin/realms/{realm}/roles/{id}

  end

  post '/roles/assign/?' do
    # Assign user to a role
    logger.debug 'Adapter: entered POST /roles/assign'
    logger.info "Content-Type is " + request.media_type
    halt 415 unless (request.content_type == 'application/json')

    form, errors = parse_json(request.body.read)
    halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors
    halt 400 unless form.is_a?(Hash)
    json_error 400, 'Username not provided' unless form.key?('username')
    json_error 400, 'Role name not provided' unless form.key?('role')

    #Translate from username to User_id
    user_id = get_user_id(form['username'])
    json_error 404, 'Username not found' if user_id.nil?

    code , msg = assign_group(form['role'], user_id)
    halt code, {'Content-type' => 'application/json'}, msg
  end

  post '/roles/unassign/?' do
    # Unassign user to a role
    logger.debug 'Adapter: entered POST /roles/unassign'
    logger.info "Content-Type is " + request.media_type
    halt 415 unless (request.content_type == 'application/json')

    form, errors = parse_json(request.body.read)
    halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors
    halt 400 unless form.is_a?(Hash)
    json_error 400, 'Username not provided' unless form.key?('username')
    json_error 400, 'Role name not provided' unless form.key?('role')

    #Translate from username to User_id
    user_id = get_user_id(form['username'])
    json_error 404, 'Username not found' if user_id.nil?

    code , msg = unassign_group(form['role'], user_id)
    halt code, {'Content-type' => 'application/json'}, msg
  end
end