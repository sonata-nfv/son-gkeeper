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
    headers 'Content-Type' => 'text/plain; charset=utf8'
    filename = 'log/development.log'
    # filename = 'log/production.log'

    # For testing purposes only
    begin
      txt = open(filename)

    rescue => err
      logger.error "Error reading log file: #{err}"
      return 500, "Error reading log file: #{err}"
    end

    halt 200, txt.read.to_s
  end
end

# Adapter-Keycloak API class
class Keycloak < Sinatra::Application
  post '/register' do
    # Return if content-type is not valid
    logger.info "Content-Type is " + request.media_type
    halt 415 unless (request.content_type == 'application/x-www-form-urlencoded' or request.content_type == 'application/json')
    #payload?={"id":"123123","auth_code":"191331","required_amount":101,"timestamp":1407775713,"status":"completed","total_amount":101}

    # Compatibility support for YAML content-type
    case request.content_type
      when 'application/x-www-form-urlencoded'
        # Validate format
        form_encoded, errors = request.body.read
        halt 400, errors.to_json if errors

        p "FORM PARAMS", form_encoded
        form = Hash[URI.decode_www_form(form_encoded)]

        # Validate Hash format
        #form, errors = validate_form(form)
        #halt 400, errors.to_json if errors

      else
        # Compatibility support for JSON content-type
        # Parses and validates JSON format
        form, errors = parse_json(request.body.read)
        halt 400, errors.to_json if errors
    end
    register_user(@access_token, form) # user_params)
  end

  post '/login' do
    logger.debug 'Adapter: entered POST /login'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    # READ FROM AUTH ENV
    #p "@client_name", self.client_name
    #p "@client_secret", self.client_secret
    user_pass = request.env["HTTP_AUTHORIZATION"].split(' ').last
    plain_user_pass  = Base64.decode64(user_pass)


    # puts "USER_PASS", user_pass
    # puts  "PLAIN", plain_user_pass.split(':').first
    # puts  "PLAIN", plain_user_pass.split(':').last
    username = plain_user_pass.split(':').first # params[:username]
    password = plain_user_pass.split(':').last # params[:password]

    credentials = {"type" => "password", "value" => password.to_s}
    login_user(username, credentials)
  end

  post '/authenticate' do
    logger.debug 'Adapter: entered POST /authenticate'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]
    auth
  end

  post '/authorize' do
    logger.debug 'Adapter: entered POST /authorize'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]
    authorize
  end

  post '/userinfo' do
    logger.debug 'Adapter: entered POST /userinfo'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    unless user_token
      error = {"ERROR" => "Access token is not provided"}
      halt 400, error.to_json
    end

    # Validate token
    res, code = token_validation(user_token)

    if code == '200'
      result = is_active?(res)
      puts "RESULT", result
      case result
        when true
          # continue
        else
          halt 400, res
      end
    else
      halt 400, res
    end

    puts "RESULT", user_token
    user_info = userinfo(user_token)
    halt 200, user_info
  end

  post '/logout' do
    logger.debug 'Adapter: entered POST /logout'
    # Return if Authorization is invalid
    halt 400 unless request.env["HTTP_AUTHORIZATION"]

    user_token = request.env["HTTP_AUTHORIZATION"].split(' ').last
    # puts "headers", request.env["HTTP_AUTHORIZATION"]

    unless user_token
      error = {"ERROR" => "Access token is not provided"}
      halt 400, error.to_json
    end

    # Validate token
    res, code = token_validation(user_token)
    # p "res,code", res, code

    if code == '200'
      result = is_active?(res)
      puts "RESULT", result
      case result
        when true
          # continue
        else
          halt 400, res
      end
    else
      halt 400, res
    end

    #if headers['Authorization']
    #  puts "AUTHORIZATION", headers['Authorization'].split(' ').last
    #end
    puts "RESULT", user_token

    logout(user_token, user=nil, realm=nil)
  end
end

=begin
class SecuredAPI < Sinatra::Application
  # This is a sample of a secured API

  get '/services' do
    # content_type :json
    # {message: "Hello, User!"}.to_json

    # scopes, user = request.env.values_at :scopes, :user
    # username = user['username'].to_sym

    # if scopes.include?('view_services') && @accounts.has_key?(username)
    # content_type :json
    # { services: @accounts[username]}.to_json
    # else
    # halt 403

    process_request request, 'view_services' do |req, username|
      content_type :json
      {services: @accounts[username]}.to_json
    end
  end

  post '/services' do
    # code
    scopes, user = request.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?('add_services') && @accounts.has_key?(username)
      service = request[:service]
      @accounts[username] << {'Service' => service}

      content_type :json
      {services: @accounts[username]}.to_json
    else
      halt 403
    end
  end

  delete '/services' do
    # code
    scopes, user = request.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?('remove_services') && @accounts.has_key?(username)
      service = request[:service]

      @accounts[username].delete_if { |h| h['Service'] == service }

      content_type :json
      {services: @accounts[username]}.to_json
    else
      halt 403
    end
  end
end
=end
