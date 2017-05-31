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
require 'yaml'

# Checks if a JSON message is valid
# @param [JSON] message some JSON message
# @return [Hash, nil] if the parsed message is a valid JSON
# @return [Hash, String] if the parsed message is an invalid JSON
def parse_json(message)
  # Check JSON message format
  begin
    parsed_message = JSON.parse(message) # parse json message
  rescue JSON::ParserError => e
    # If JSON not valid, return with errors
    logger.error "JSON parsing: #{e}"
    return message, e.to_s + "\n"
  end

  return parsed_message, nil
end

def keyed_hash(hash)
  Hash[hash.map { |(k, v)| [k.to_sym, v] }]
end

def json_error(code, message)
  #log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  #STDOUT.reopen(log_file)
  #STDOUT.sync = true
  #puts 'CODE', code.to_s
  #puts 'MESSAGE', message.to_s
  msg = {'error' => message}
  logger.error(code.to_s + ',' + msg.to_s)
  #STDOUT.sync = false
  halt code, {'Content-type' => 'application/json'}, msg.to_json
end

def apply_limit_and_offset(input, offset= nil, limit= nil)
  @result = input
  @result = offset ? input.drop(offset.to_i) : @result
  @result = limit ? @result.first(limit.to_i) : @result
end

def create_public_key
  # Turn keycloak realm pub key into an actual openssl compat pub key
  keycloak_yml = YAML.load_file('config/keycloak.yml')
  keycloak_config = JSON.parse(File.read('config/keycloak.json'))
  @s = "-----BEGIN PUBLIC KEY-----\n"
  @s += keycloak_yml['realm_public_key'].scan(/.{1,64}/).join("\n")
  @s += "\n-----END PUBLIC KEY-----\n"
  @key = OpenSSL::PKey::RSA.new @s
  set :keycloak_pub_key, @key
  set :keycloak_client_id, keycloak_config['resource']
  set :keycloak_url, keycloak_config['auth-server-url'] + '/' + keycloak_config['realm'] + '/'
end

def query_string
  request.env['QUERY_STRING'].nil? ? '' : request.env['QUERY_STRING'].to_s
end

def request_url
  request.env['rack.url_scheme'] + '://' + request.env['HTTP_HOST'] + request.env['REQUEST_PATH']
end

class Adapter < Sinatra::Application
  # Method which lists all available interfaces
  # @return [Array] an array of hashes containing all interfaces
  def interfaces_list
    [
        {
            'uri' => '/',
            'method' => 'GET',
            'purpose' => 'REST API root'
        },
        {
            'uri' => '/log',
            'method' => 'GET',
            'purpose' => 'User Management API log'
        },
        {
            'uri' => '/config',
            'method' => 'GET',
            'purpose' => 'User Management current configuration'
        },
        {
            'uri' => '/refresh',
            'method' => 'GET',
            'purpose' => 'User Management refresh token endpoint'
        }
    ]
  end

  def process_request req, scope
    scopes, user = req.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?(scope) && @accounts.has_key?(username)
      yield req, username
    else
      halt 403
    end
  end

  def self.assign_group(attr)
    # DEPRECATED
    case attr
      when 'developer'
        return 'developers'
      when 'customer'
        return 'customers'
      else
        json_error(400, 'No group available')
    end
  end

  def authorize!
    # DEPRECATED
    # @decoded_token = JWT.decode @access_token, settings.keycloak_pub_key, true, { :algorithm => 'RS256' }
    @decoded_payload, @decoded_header = JWT.decode @access_token, settings.keycloak_pub_key, true, { :algorithm => 'RS256' }
    # puts "DECODED_TOKEN: ", @decoded_token
    puts "DECODED_HEADER: ", @decoded_header
    puts "DECODED_PAYLOAD: ", @decoded_payload

    # @email = @decoded_token[0]["email"]
    # @id = @decoded_token[0]["sub"]
    # @user = @decoded_token[0]["preferred_username"]
    @email = @decoded_payload["email"]
    @id = @decoded_payload["sub"]
    @user = @decoded_payload["preferred_username"]
    # puts "ID?", @id
    puts "EMAIL?", @email
    halt 401, "ACCESS DENIED: No email address provided!" if @email.nil?

    # "realm_access"=>{"roles"=>["uma_authorization"]}
    @decoded_realm_roles = @decoded_payload["realm_access"]["roles"]
    puts "REALM_ROLES?", @decoded_realm_roles
    # "resource_access"=>{"son-connect"=>{"roles"=>["sonata_access"]}}
    client_access = @decoded_payload["resource_access"].first# [0]["roles"] returns ['son-connect',{'roles'=>['son,...']}]
    @decoded_user_roles = client_access[1]["roles"] # key, value -> [0][1]
    puts "USER_ROLES?", @decoded_user_roles
  end

  def set_keycloak_config()
    #TODO: Implement
    conf = YAML::load_file('../config/keycloak.yml') #Load
    conf['address'] = 'localhost'
    conf['port'] = 8081
    conf['uri'] = 'auth' #Modify
    conf['realm'] = 'SONATA' #Modify
    conf['client'] = 'adapter' #Modify
    # conf['secret'] = ''
    File.open('../config/keycloak.yml', 'w') {|f| f.write conf.to_yaml } #Store
  end

  def set_sonata_realm()
    # DEPRECATED
    # Requirement: pre-defined SONATA Realm json template:
    # ./standalone.sh -Dkeycloak.migration.action=export -Dkeycloak.migration.provider=singleFile -Dkeycloak.migration.file=</path/to/template.json>
    # Then, import template into Keycloak thorugh REST API:
    # Imports a realm from a full representation of that realm.
    # POST /admin/realms
    # BodyParameter = JSON representation of the realm
  end

  def set_adapter_client()
    # DEPRECATED
    # Create a new client

    # set Client's client_id must be unique!
    # generate uuid client secret -> call set_adapter_client_credentials()
    # import pre-made Adapter client template
    # set client secret in template
    # POST /admin/realms/{realm}/clients
    # BodyParameter = ClientRepresentation
    #r ealm = realm name (not id!)
  end

  def set_adapter_client_credentials()
    # DEPRECATED
    # generate uuid
    # save generated uuid secret in config/keycloak.yml
    conf = YAML::load_file('../config/keycloak.yml') #Load
    conf['client'] = 'adapter' #Modify
    conf['secret'] = '' #Modify
    # conf['secret'] = ''
    File.open('../config/keycloak.yml', 'w') {|f| f.write conf.to_yaml } #Store
    # client: adapter
    # secret: <generated uuid>
    # return uuid to set_adapter_client()
  end

  def get_client_secret()
    # DEPRECATED
    realm = "master"
    id = "adapter"
    # Get the client secret
    url = URI("http://localhost:8081/auth/admin/realms/#{realm}/clients/#{id}/client-secret")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)
    request.basic_auth("admin", "admin") # <--- Needs bearer token
    request["content-type"] = 'application/json'

    response = http.request(request)
    p "RESPONSE", response
    p "RESPONSE.read_body222", response.read_body
  end

  def regenerate_client_secret()
    # Generate a new secret for the client
    # POST /admin/realms/{realm}/clients/{id}/client-secret
  end

  def set_keycloak_credentials()
    # Other Keycloak credentials that might be configured
  end
end