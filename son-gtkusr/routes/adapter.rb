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

  @@access_token = nil

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
    logger.info 'User Management is configured and ready'
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
    code, access_token = refresh_adapter
    # access_token = Keycloak.get_adapter_token
    logger.debug "Adapter: exit from GET /refresh with token #{access_token}"
    halt code.to_i
  end
end