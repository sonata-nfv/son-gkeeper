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


# Adapter class
class Adapter < Sinatra::Application
  # @method get_root
  # @overload get '/'
  # Get all available interfaces
  # -> Get all interfaces
  get '/' do
    headers 'Content-Type' => 'text/plain; charset=utf8'
    halt 200, interfaces_list.to_json
  end

  # @method get_log
  # @overload get '/adapter/log'
  # Returns contents of log file
  # Management method to get log file of adapter remotely
  get '/log' do
    logger.debug 'Adapter: entered GET /admin/log'
    headers 'Content-Type' => 'text/plain; charset=utf8'
    #filename = 'log/development.log'
    filename = 'log/production.log'

    # For testing purposes only
    begin
      txt = open(filename)

    rescue => err
      logger.error "Error reading log file: #{err}"
      json_error(500, "Error reading log file: #{err}")
    end

    halt 200, txt.read.to_s
  end

  get '/config' do
    # This endpoint returns the Keycloak public key
    logger.debug 'Adapter: entered GET /admin/config'

    begin
      keycloak_yml = YAML.load_file('config/keycloak.yml')
    rescue => err
      logger.error "Error loading config file: #{err}"
      json_error(500, "Error loading config file: #{err}")
    end
    halt 200, keycloak_yml.to_json
  end
end

# Adapter-Keycloak API class
class Keycloak < Sinatra::Application
  
  post '/config' do
    logger.debug 'Adapter: entered POST /config'
    # log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    # STDOUT.reopen(log_file)
    # STDOUT.sync = true
    # puts "REQUEST.IP:", request.ip.to_s
    # puts "@@ADDRESS:", @@address.to_s
    begin
      keycloak_address = Resolv::Hosts.new.getaddress(ENV['KEYCLOAK_ADDRESS'])
    rescue
      keycloak_address = Resolv::DNS.new.getaddress(ENV['KEYCLOAK_ADDRESS'])
    end
    logger.debug "Checking #{request.ip.to_s} with #{keycloak_address.to_s}"
    # STDOUT.sync = false
    # Check if the request comes from keycloak docker.
    if request.ip.to_s !=  keycloak_address.to_s
      halt 401
    end
    if defined? @@client_secret
      json_error(409, "Secret key is already defined")
    end
    
    @@client_secret = params['secret']
    get_oidc_endpoints
    get_adapter_install_json
    @@access_token = self.get_adapter_token
    logger.debug 'Adapter: exit POST /config with secret and access_token configured'
    halt 200
  end

  get '/public-key' do
    # This endpoint returns the Keycloak public key
    logger.debug 'Adapter: entered GET /public-key'
    keycloak_yml = YAML.load_file('config/keycloak.yml')
    unless keycloak_yml['realm_public_key']
      Keycloak.get_realm_public_key
      keycloak_yml = YAML.load_file('config/keycloak.yml')
    end

    response = {"public-key" => keycloak_yml['realm_public_key'].to_s}
    halt 200, {'Content-type' => 'application/json'}, response.to_json
  end

  get '/refresh' do
    # This endpoint forces the Adapter to resfresh the token
    logger.debug 'Adapter: entered GET /refresh'
    access_token = refresh_adapter
    # access_token = Keycloak.get_adapter_token
    logger.debug "Adapter: exit from GET /refresh with token #{access_token}"
  end

  post '/register/user' do
    logger.debug 'Adapter: entered POST /register/user'
    # Return if content-type is not valid
    logger.info "Content-Type is " + request.media_type
    # halt 415 unless (request.content_type == 'application/x-www-form-urlencoded' or request.content_type == 'application/json')
    json_error(415, 'Only Content-type: application/json is supported') unless (request.content_type == 'application/json')

    # Compatibility support for JSON content-type
    # Parses and validates JSON format
    form, errors = parse_json(request.body.read)
    halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors
    unless form.key?('enabled')
      form = form.merge({'enabled'=> true})
    end

    # pkey and cert will be nil if they does not exist
    pkey = form['attributes']['public_key']
    form['attributes'].delete('public_key')

    cert = form['attributes']['certificate']
    form['attributes'].delete('certificate')

    if pkey || cert
      if form['attributes']['userType'].is_a?(Array)
        if form['attributes']['userType'].include?('developer')
          # proceed
        else
          logger.debug 'Adapter: leaving POST /register/user with userType error'
          json_error(400, 'Registration failed! Only developer role support public_key attribute')
        end
      elsif form['attributes']['userType']
        case form['attributes']['userType']
          when 'developer'
            # proceed
          else
            logger.debug 'Adapter: leaving POST /register/user with userType error'
            json_error(400, 'Bad userType! Only developer role support public_key attribute')
        end
      end
    end

    logger.info "Registering new user"
    user_id, error_code, error_msg = register_user(form)

    if user_id.nil?
      if error_code == 409
        halt error_code, {'Content-type' => 'application/json'}, error_msg
      end
      delete_user(form['username'])
      # json_error(error_code, error_msg)
      halt error_code, {'Content-type' => 'application/json'}, error_msg
    end

    form['attributes']['userType'].each { |attr|
      # puts "SETTING_USER_ROLE", attr
      logger.debug "Adding new user to groups"
      res_code, res_msg = set_user_groups(attr, user_id)
      if res_code != 204
        delete_user(form['username'])
        halt res_code.to_i, {'Content-type' => 'application/json'}, res_msg
      end
      logger.debug "Adding new user roles"
      res_code, res_msg = set_user_roles(attr, user_id)
      if res_code != 204
        delete_user(form['username'])
        halt res_code.to_i, {'Content-type' => 'application/json'}, res_msg
      end
    }

    # Check if username already exists in the database
    begin
      user = Sp_user.find_by({ 'username' => form['username']})
      delete_user(form['username'])
      json_error 409, 'Duplicated username'
    rescue Mongoid::Errors::DocumentNotFound => e
      # Continue
    end
    # Check if user ID already exists in the database
    begin
      user = Sp_user.find_by({ '_id' => user_id })
      delete_user(form['username'])
      json_error 409, 'Duplicated user ID'
    rescue Mongoid::Errors::DocumentNotFound => e
      # Continue
    end

    # Save to DB
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

  post '/register/service' do
    logger.debug 'Adapter: entered POST /register/service'
    # Return if content-type is not valid
    logger.info "Content-Type is " + request.media_type
    halt 415 unless (request.content_type == 'application/x-www-form-urlencoded' or request.content_type == 'application/json')

    # TODO: Do some validations to the serviceForm
    # Compatibility support for JSON content-type
    # Parses and validates JSON format
    parsed_form, errors = parse_json(request.body.read)
    halt 400, errors.to_json if errors

    # puts "REGISTERING NEW CLIENT"
    logger.info 'Registering new Service client'
    client_id = register_client(parsed_form)

    if client_id.nil?
      delete_client(parsed_form['clientId'])
      json_error(400, 'Service client registration failed')
    end

    # TODO: To solve predefined roles dependency, create a new role based on client registration
    # New role should have Client Id (name) of service
    # puts "SETTING CLIENT ROLES"

    client_data, role_data, error_code, error_msg = set_service_roles(parsed_form['clientId'])
    if error_code != nil
      delete_client(parsed_form['clientId'])
      halt error_code, {'Content-type' => 'application/json'}, error_msg
    end
    # puts "SETTING SERVICE ACCOUNT ROLES"
    code, error_msg = set_service_account_roles(client_data['id'], role_data)
    if code != 204
      delete_client(parsed_form['clientId'])
      halt code, {'Content-type' => 'application/json'}, error_msg
    end
    logger.info "New Service client #{parsed_form['clientId']} registered"
    halt 201
  end

  post '/login/user' do
    logger.debug 'Adapter: entered POST /login/user'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    #p "@client_name", self.client_name
    #p "@client_secret", self.client_secret
    pass = request.env["HTTP_AUTHORIZATION"].split(' ').last
    plain_pass  = Base64.decode64(pass)

    # puts  "PLAIN", plain_user_pass.split(':').first
    # puts  "PLAIN", plain_user_pass.split(':').last
    username = plain_pass.split(':').first # params[:username]
    password = plain_pass.split(':').last # params[:password]
    logger.info "User #{username} has accessed to log-in"

    credentials = {"type" => "password", "value" => password.to_s}
    log_code, log_msg = login(username, credentials)
    if log_code != 200
      logger.info "User #{username} has failed to log-in"
      logger.debug 'Adapter: exit POST /login/user'
      halt log_code, {'Content-type' => 'application/json'}, log_msg
    end
    logger.info "User #{username} has logged-in succesfully"
    logger.debug 'Adapter: exit POST /login/user'
    halt log_code, {'Content-type' => 'application/json'}, log_msg
  end

  post '/login/service' do
    logger.debug 'Adapter: entered POST /login/service'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    pass = request.env["HTTP_AUTHORIZATION"].split(' ').last
    plain_pass  = Base64.decode64(pass)

    client_id = plain_pass.split(':').first
    secret = plain_pass.split(':').last
    logger.info "Service #{client_id} has accessed to log-in"

    credentials = {"type" => "client_credentials", "value" => secret.to_s}
    log_code, log_msg = login(client_id, credentials)
    if log_code != 200
      logger.info "Service #{client_id} has failed to log-in"
      logger.debug 'Adapter: exit POST /login/service'
      halt log_code, {'Content-type' => 'application/json'}, log_msg
    end
    logger.info "Service #{client_id} has logged-in successfully"
    logger.debug 'Adapter: exit POST /login/service'
    halt log_code, {'Content-type' => 'application/json'}, log_msg
  end

  post '/authenticate' do
    logger.debug 'Adapter: entered POST /authenticate'
    logger.info 'POST /authenticate is deprecated! It returns an ID token which is currently unused'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]
    keyed_params = params

    case keyed_params[:grant_type]
      when 'password' # -> user
        authenticate(keyed_params[:client_id],
                     keyed_params[:username],
                     keyed_params[:password],
                     keyed_params[:grant_type])

      when 'client_credentials' # -> service
        authenticate(keyed_params[:client_id],
                     nil,
                     keyed_params[:client_secret],
                     keyed_params[:grant_type])
      else
        json_error(400, 'Bad request')
      end
  end

  get '/authorize' do
    logger.debug 'Adapter: entered POST /authorize'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    # Get authorization token
    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      logger.debug 'Adapter: exit POST /authorize without access token'
      json_error(400, 'Access token is not provided')
    end

    # Check token validation
    val_res, val_code = token_validation(user_token)
    logger.debug "Token evaluation: #{val_code} - #{val_res}"
    # Check token expiration
    if val_code.to_s == '200'
      result = is_active?(val_res)
      # puts "RESULT", result
      case result
        when false
          logger.debug 'Adapter: exit POST /authorize without valid access token'
          json_error(401, 'Token not active')
        else
          # continue
      end
    else
      logger.debug 'Adapter: exit POST /authorize with valid access token'
      halt 401, {'Content-type' => 'application/json'}, val_res
    end
    logger.info 'Authorization request received at /authorize'
    # Return if content-type is not valid
    # log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    # STDOUT.reopen(log_file)
    # STDOUT.sync = true
    # puts "Content-Type is " + request.content_type
    if request.content_type
      logger.info "Request Content-Type is #{request.content_type}"
    end
    # halt 415 unless (request.content_type == 'application/x-www-form-urlencoded' or request.content_type == 'application/json')
    # We will accept both a JSON file, form-urlencoded or query type
    # Compatibility support
    case request.content_type
      when 'application/x-www-form-urlencoded'
        # Validate format
        # form_encoded, errors = request.body.read
        # halt 400, errors.to_json if errors

        # p "FORM PARAMS", form_encoded
        # form = Hash[URI.decode_www_form(form_encoded)]
        # mat
        # p "FORM", form
        # keyed_params = keyed_hash(form)
        # halt 401 unless (keyed_params[:'path'] and keyed_params[:'method'])

        # Request is a QUERY TYPE
        # Get request parameters
        logger.info "Request parameters are #{params}"
        # puts "Input params", params
        keyed_params = keyed_hash(params)
        # puts "KEYED_PARAMS", keyed_params
        # params examples: {:path=>"catalogues", :method=>"GET"}
        # Halt if 'path' and 'method' are not included
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])

      when 'application/json'
        # Compatibility support for JSON content-type
        # Parses and validates JSON format
        form, errors = parse_json(request.body.read)
        halt 400, errors.to_json if errors
        # p "FORM", form
        logger.info "Request parameters are #{form.to_s}"
        keyed_params = keyed_hash(form)
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])
      else
        # Request is a QUERY TYPE
        # Get request parameters
        logger.info "Request parameters are #{params}"
        keyed_params = keyed_hash(params)
        # puts "KEYED_PARAMS", keyed_params
        # params examples: {:path=>"catalogues", :method=>"GET"}
        # Halt if 'path' and 'method' are not included
        json_error(401, 'Parameters "path=" and "method=" not found') unless (keyed_params[:path] and keyed_params[:method])
        # halt 401, json_error("Invalid Content-type")
      end

    # TODO: Handle alternative authorization requests
    # puts "PATH", keyed_params[:'path']
    # puts "METHOD",keyed_params[:'method']
    # Check the provided path to the resource and the HTTP method, then build the request
    request = process_request(keyed_params[:path], keyed_params[:method])

    logger.info 'Evaluating Authorization request'
    # Authorization process
    auth_code, auth_msg = authorize?(user_token, request)
    if auth_code.to_i == 200
      halt auth_code.to_i
    else
      json_error(auth_code, auth_msg)
    end
    # STDOUT.sync = false
  end

  post '/userinfo' do
    logger.debug 'Adapter: entered POST /userinfo'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      json_error(400, 'Access token is not provided')
    end

    # Validate token
    res, code = token_validation(user_token)
    if code == '200'
      result = is_active?(res)
      # puts "RESULT", result
      case result
        when false
          json_error(401, 'Token not active')
        else
          # continue
      end
    else
      json_error(400, res.to_s)
    end

    # puts "RESULT", user_token
    user_info = userinfo(user_token)
    halt 200, {'Content-type' => 'application/json'}, user_info
  end

  get '/userid' do
    logger.debug 'Adapter: entered POST /userid'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      json_error(400, 'Access token is not provided')
    end

    # Validate token
    res, code = token_validation(user_token)
    token_contents = JSON.parse(res)
    if code == '200'
      result = is_active?(res)
      case result
        when false
          json_error(401, 'Token not active')
        else
          # continue
      end
    else
      json_error(400, res.to_s)
    end

    keyed_params = keyed_hash(params)
    if keyed_params.include? :username
      user_id = get_user_id(keyed_params[:username])
      response = {'userId' => user_id}
      halt 200, {'Content-type' => 'application/json'}, response.to_json
    elsif token_contents['sub']
      response = {'userId' => token_contents['sub']}
      halt 200, {'Content-type' => 'application/json'}, response.to_json
    else
      json_error(400, 'Bad token or incorrect username')
    end
  end

  post '/logout' do
    logger.debug 'Adapter: entered POST /logout'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    # puts "headers", request.env["HTTP_AUTHORIZATION"]

    unless user_token
      json_error(400, 'Access token is not provided')
    end

    # Validate token
    res, code = token_validation(user_token)
    # p "res,code", res, code

    if code == '200'
      result = is_active?(res)
      # puts "RESULT", result
      case result
        when false
          json_error(401, 'Token not active')
        else
          # continue
      end
    else
      halt 400, {'Content-type' => 'application/json'}, res
    end

    # if headers['Authorization']
    #   puts "AUTHORIZATION", headers['Authorization'].split(' ').last
    # end
    # puts "RESULT", user_token

    log_code = logout(user_token, user=nil, realm=nil)
    halt log_code
  end

  get '/users' do
    # This endpoint allows queries for the next fields:
    # search, lastName, firstName, email, username, first, max
    logger.debug 'Adapter: entered GET /users'
    logger.debug "Adapter: Query parameters #{params}"
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(id lastName firstName email username)

    logger.debug "Adapter: Optional query #{queriables}"

    if params.length > 1
      json_error(400, 'Too many arguments')
    end

    # logger.debug "Adapter: params first #{params.first}"
    if params.first
      k, v = params.first
      # logger.debug "Adapter: k value #{k}"
      unless queriables.include? k
        json_error(400, 'Bad query')
      end
    else
      k, v = nil, nil
    end
    case k
      when 'id'
        code, user_data = get_user(v)
        if code.to_i != 200
          halt 200, {'Content-type' => 'application/json'}, [].to_json
        end
        reg_users = [JSON.parse(user_data)]
        logger.debug "Adapter: get_user value #{reg_users}"
      else
        reg_users = JSON.parse(get_users(params))
    end

    #reg_users is an array of hashes
    new_reg_users = []
    reg_users.each do |user_data|
      # call keycloak.rb method here?
      user_id = user_data['id']
      # call mongoDB to receive user_extra_data
      begin
        user_extra_data = Sp_user.find_by({ '_id' => user_id })
      rescue Mongoid::Errors::DocumentNotFound => e
        logger.debug 'Adapter: Error caused by DocumentNotFound in user database'
        # Continue?
      end
      user_extra_data = user_extra_data.to_json(:except => [:_id, :id, :username, :updated_at, :created_at])
      user_extra_data = {'attributes' => parse_json(user_extra_data)[0]}
      merged_user_data = user_data.deep_merge(user_extra_data)
      new_reg_users << merged_user_data
    end

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT
    new_reg_users = apply_limit_and_offset(new_reg_users, offset=params[:offset], limit=params[:limit])
    halt 200, {'Content-type' => 'application/json'}, new_reg_users.to_json
  end

  put '/users' do
    # This endpoint allows queries for the next fields:
    # search, lastName, firstName, email, username, first, max
    logger.debug 'Adapter: entered PUT /users'
    logger.debug "Adapter: query parameters #{params}"
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(id username)
    not_updatables = %w(id username email)
    logger.debug "Adapter: Optional query #{queriables}"
    json_error(400, 'Bad query') if params.empty?
    if params.length > 1
      json_error(400, 'Too many arguments')
    end

    k, v = params.first
    unless queriables.include? k
      logger.debug 'Adapter: Query includes forbidden parameter'
      json_error(400, 'Bad query')
    end
    form, errors = parse_json(request.body.read)

    pkey = nil
    cert = nil
    # Check form keys
    form.each { |att, val|
      if not_updatables.include? att
        json_error(400, 'Bad query')
      end

      case att
        when 'attributes'
          begin
            pkey = form['attributes']['public_key']
            form['attributes'].delete('public_key')
          rescue
            # pkey = nil
          end
          begin
            cert = form['attributes']['certificate']
            form['attributes'].delete('certificate')
          rescue
            # cert = nil
          end
        else
      end
    }

    case k
      when 'id'
        code, @msg = update_user(nil, v, form)
      when 'username'
        code, @msg = update_user(v, nil, form)
      else
        code = 400
        json_error(400, 'Bad query')
    end

    if form['attributes']['userType'].is_a?(Array)
      if form['attributes']['userType'].include?('developer')
        # proceed
      else
        logger.debug 'Adapter: leaving PUT /users'
        halt 204
      end
    elsif form['attributes']['userType']
      case form['attributes']['userType']
        when 'developer'
          # proceed
        else
          logger.debug 'Adapter: leaving PUT /users'
          halt 204
      end
    else
      # Check userType in user stored data
      u_code, u_data = get_user(@msg)
      if u_code.to_i != 200
        json_error(400, 'Update failed')
      else
        if u_data['attributes']['userType'].is_a?(Array)
          if u_data['attributes']['userType'].include?('developer')
            # proceed
          else
            logger.debug 'Adapter: leaving PUT /users'
            halt 204
          end
        elsif u_data['attributes']['userType']
          case u_data['attributes']['userType']
            when 'developer'
              # proceed
            else
              logger.debug 'Adapter: leaving PUT /users'
              halt 204
          end
        end
      end
    end

    if code.nil?
      begin
        user_extra_data = Sp_user.find_by({ '_id' => @msg })
      rescue Mongoid::Errors::DocumentNotFound => e
        logger.debug 'Adapter: Error caused by DocumentNotFound in user database'
        halt 204
      end
      case pkey
        when nil
        else
          begin
            user_extra_data.update_attributes(public_key: pkey)
          rescue Moped::Errors::OperationFailure => e
            json_error(400, e)
          end
      end
      case cert
        when nil
        else
          begin
            user_extra_data.update_attributes(certificate: cert)
          rescue Moped::Errors::OperationFailure => e
            json_error(400, e)
          end
      end
      logger.debug 'Adapter: leaving PUT /users'
      halt 204
    end
    halt code, {'Content-type' => 'application/json'}, @msg
  end

  delete '/users' do
    # This endpoint allows queries for the next fields:
    # search, lastName, firstName, email, username, first, max
    logger.debug 'Adapter: entered DELETE /users'
    logger.debug "Adapter: required query #{params}"
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(id username)

    logger.debug "Adapter: Available queriables #{queriables}"

    json_error(400, 'Bad query') if params.empty?
    if params.length > 1
      json_error(400, 'Too many arguments')
    end

    k, v = params.first
    unless queriables.include? k
      json_error(400, 'Bad query')
    end

    case k
      when 'id'
      code, msg = delete_user_by_id(nil, v)
      # logger.debug "Adapter: delete user message #{msg}"
      when 'username'
      code, msg = delete_user_by_id(v, nil)
      # logger.debug "Adapter: delete user message #{msg}"
      else
      json_error(400, 'Bad query')
    end
    if code.nil?
      begin
        user_extra_data = Sp_user.find_by({ '_id' => msg })
      rescue Mongoid::Errors::DocumentNotFound => e
        logger.debug 'Adapter: Error caused by DocumentNotFound in user database'
        halt 204
        # Continue?
      end
      user_extra_data.destroy
      logger.debug 'Adapter: leaving DELETE /users'
      halt 204
    end
    halt code
  end

  get '/services' do
    # This endpoint allows queries for the next fields:
    # name
    logger.debug 'Adapter: entered GET /services'
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(name id)

    if params.length > 1
      json_error(400, 'Too many arguments')
    end

    if params.first
      k, v = params.first
      # logger.debug "Adapter: k value #{k}"
      unless queriables.include? k
        json_error(400, 'Bad query')
      end
    end

    reg_clients = JSON.parse(get_clients(params))

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT
    reg_clients = apply_limit_and_offset(reg_clients, offset=params[:offset], limit=params[:limit])
    logger.debug 'Adapter: leaving GET /services'
    halt 200, {'Content-type' => 'application/json'}, reg_clients.to_json
  end

  put '/services' do
    # TODO: TO BE IMPLEMENTED
  end

  delete '/services' do
    # This endpoint allows queries for the next fields:
    # name
    logger.debug 'Adapter: entered DELETE /services'
    logger.debug "Adapter: required query #{params}"
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    queriables = %w(name id)

    json_error(400, 'Bad query') if params.empty?
    if params.length > 1
      json_error(400, 'Too many arguments')
    end

    k, v = params.first
    unless queriables.include? k
      json_error(400, 'Bad query')
    end

    case k
      when 'id'
        delete_client(v)
        logger.debug 'Adapter: leaving DELETE /services'
        halt 204
      when 'username'
        reg_client, errors = parse_json(get_clients(params))
        halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors
        delete_client(reg_client['id'])
        logger.debug 'Adapter: leaving DELETE /services'
        halt 204
      else
        json_error(400, 'Bad query')
    end
  end

  get '/roles' do
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
    realm_roles = apply_limit_and_offset(realm_roles, offset=params[:offset], limit=params[:limit])
    halt code.to_i, {'Content-type' => 'application/json'}, realm_roles
  end

  put '/roles' do

  end

  delete '/roles' do

  end

  get '/sessions/users' do
    # Get all user sessions
    # Returns a list of user sessions associated with the adapter client
    # GET /admin/realms/{realm}/clients/{id}/user-sessions
    logger.debug 'Adapter: entered GET /sessions/users'
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    adapter_id = get_client_id('adapter')
    ses_code, ses_msg = get_sessions('user', adapter_id)

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT
    ses_msg = apply_limit_and_offset(ses_msg, offset=params[:offset], limit=params[:limit])
    halt ses_code.to_i, {'Content-type' => 'application/json'}, ses_msg
  end

  get '/sessions/users/:username/?' do
    # Get user sessions
    # Returns a list of sessions associated with the user
    unless params[:username].nil?
      logger.debug "Adapter: entered GET /sessions/users/#{params[:username]}"

      # Return if Authorization is invalid
      # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]

      user_id = get_user_id(params[:username])
      if user_id.nil?
        json_error(404, 'Username not found')
      end
      ses_code, ses_msg = get_user_sessions(user_id)

      params['offset'] ||= DEFAULT_OFFSET
      params['limit'] ||= DEFAULT_LIMIT
      ses_msg = apply_limit_and_offset(ses_msg, offset=params[:offset], limit=params[:limit])
      halt ses_code.to_i, {'Content-type' => 'application/json'}, ses_msg
    end
    logger.debug 'Adapter: leaving GET /sessions/users/ with no username specified'
    json_error 400, 'No username specified'
  end

  get '/sessions/services' do
    # Get all service client sessions
    # Returns a list of service client sessions
    logger.debug 'Adapter: entered GET /sessions/services'
    # Return if Authorization is invalid
    # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
    # adapter_id = get_adapter_id
    ses_code, ses_msg = get_sessions('service', nil)

    params['offset'] ||= DEFAULT_OFFSET
    params['limit'] ||= DEFAULT_LIMIT
    ses_msg = apply_limit_and_offset(ses_msg, offset=params[:offset], limit=params[:limit])
    halt ses_code.to_i, {'Content-type' => 'application/json'}, ses_msg
  end

  get '/sessions/services/:clientId/?' do
    # Get service client sessions
    # Returns a list of sessions associated with the client service user
  end

  put '/signatures/:username/?' do
    # Update user public key and certificate attributes
    unless params[:username].nil?
      logger.debug "Adapter: entered PUT /signatures/#{params[:username]}"

      # Return if Authorization is invalid
      # json_error(400, 'Authorization header not set') unless request.env["HTTP_AUTHORIZATION"]
      user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
      unless user_token
        json_error(400, 'Access token is not provided')
      end

      # Validate token
      res, code = token_validation(user_token)
      token_contents = JSON.parse(res)

      if code == '200'
        result = is_active?(res)
        case result
          when false
            json_error(401, 'Token not active')
          else
            # continue
        end
      else
        json_error(400, res.to_s)
      end
      logger.debug "Adapter: Token contents #{token_contents}"
      logger.debug "Adapter: Username #{params[:username]}"

      if token_contents['username'].to_s == params[:username].to_s
        logger.debug "Adapter: #{params[:username]} matches Access Token"
        # Translate from username to User_id
        user_id = get_user_id(params[:username])
        if user_id.nil?
          json_error(404, 'Username not found')
        end
        logger.info "Content-Type is " + request.media_type
        halt 415 unless (request.content_type == 'application/json')

        form, errors = parse_json(request.body.read)
        halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors

        halt 400 unless form.is_a?(Hash)
        unless form.key?('public_key')
         json_error(400, 'Developer public key not provided')
        end

        unless form.key? ('certificate')
          form['certs'] = nil
        end

        # Get user public key and certificate
        # Check if user ID already exists in the database
        begin
          user = Sp_user.find_by({ '_id' => user_id })
        rescue Mongoid::Errors::DocumentNotFound => e
          json_error(404, 'Username not found')
        end

        # Add new son-package attribute fields
        begin
          user.update_attributes(public_key: form['public_key'], certificate: form['certificate'])
        rescue Moped::Errors::OperationFailure => e
          json_error(400, 'Update failed')
        end
      else
        json_error(400, 'Provided username does not match with Access Token')
      end
      halt 200 # , {'Content-type' => 'application/json'}, 'User signature successfully updated'
    end
    logger.debug 'Adapter: leaving PUT /signatures/ with no username specified'
    json_error(400, 'No username specified')
  end

  put '/attributes/:username/?' do
    # Update user account attributes
    unless params[:username].nil?
      logger.debug "Adapter: entered PUT /attributes/#{params[:username]}"

      # Return if Authorization is invalid
      # halt 400 unless request.env["HTTP_AUTHORIZATION"]
      user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
      unless user_token
        json_error(400, 'Access token is not provided')
      end

      # Validate token
      res, code = token_validation(user_token)
      token_contents = JSON.parse(res)

      if code == '200'
        result = is_active?(res)
        case result
          when false
            json_error(401, 'Token not active')
          else
            # continue
        end
      else
        json_error(400, res.to_s)
      end
      logger.debug "Adapter: Token contents #{token_contents}"
      logger.debug "Adapter: Username #{params[:username]}"
      # if token_contents['sub'] == :username
      if token_contents['username'].to_s == params[:username].to_s
        logger.debug "Adapter: #{params[:username]} matches Access Token"
        #Translate from username to User_id
        user_id = get_user_id(params[:username])
        if user_id.nil?
          json_error 404, 'Username not found'
        end
        logger.info "Content-Type is " + request.media_type
        halt 415 unless (request.content_type == 'application/json')

        form, errors = parse_json(request.body.read)
        halt 400, {'Content-type' => 'application/json'}, errors.to_json if errors

        halt 400 unless form.is_a?(Hash)
        unless form.key?('public_key')
          json_error 400, 'Developer public key not provided'
        end

        unless form.key? ('certificate')
          form['certs'] = nil
        end

        # Get user attributes
        # user_data = get_users({'id' => user_id})
        # parsed_user_data = JSON.parse(user_data)[0]
        # logger.debug "parsed_user_data #{parsed_user_data}"

        # DEVELOPER'S PUBLIC KEY AND CERTIFICATE WILL BE STORED IN MONGODB
        # user_attributes = parsed_user_data['attributes']
        # logger.debug "user_attributes #{user_attributes}"
        # unless user_attributes['userType'][0] == 'developer'
        #   json_error 400, 'User is not a developer'
        # end

        # Update attributes
        # new_attributes = {"public-key" => [form['public-key']], "certificate" => [form['certificate']]}
        # logger.debug "new_attributes #{new_attributes}"
        # new_user_attributes = user_attributes.merge(new_attributes)
        # logger.debug "new_user_attributes #{new_user_attributes}"
        # upd_code, upd_msg = update_user_pkey(user_id, new_user_attributes)
        # else
        # json_error 400, 'Provided username does not match with Access Token'
      end
      # halt upd_code.to_i, {'Content-type' => 'application/json'}, upd_msg
    end
    logger.debug 'Adapter: leaving PUT /attributes/ with no username specified'
    json_error 400, 'No username specified'
  end
end
