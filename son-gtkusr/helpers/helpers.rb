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
  log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  STDOUT.reopen(log_file)
  STDOUT.sync = true
  puts 'CODE', code.to_s
  puts 'MESSAGE', message.to_s
  msg = {'error' => message}
  logger.error msg.to_s
  STDOUT.sync = false
  halt code, {'Content-type' => 'application/json'}, msg.to_json
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
            'purpose' => 'User Management log'
        },
        {
            'uri' => '/config',
            'method' => 'GET',
            'purpose' => 'User Management configuration'
        },
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
    # TODO: UPDATE THIS! Use mapping settings to configure?
    # Supported attrs = developer, customer
    # Supported groups = Developers, Customers
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
    # curl -d "client_id=admin-cli" -d "username=user1" -d "password=1234" -d "grant_type=password" "http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token"
    client_id = "service"
    @usrname = "user1"
    pwd = "1234"
    grt_type = "password"
    clt_assert = "{JWT_BEARER_TOKEN}"
    clt_assert_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
    # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

    uri = URI(http_path)
    res = Net::HTTP.post_form(uri, 'client_id' => client_id,
                              'username' => @usrname,
                              'password' => pwd,
                              'grant_type' => grt_type)
    #puts "RES.BODY: ", res.body

    if res.body['access_token']
      #if env['HTTP_AUTHORIZATION']
      # puts "env: ", env['HTTP_AUTHORIZATION']
      # access_token = env['HTTP_AUTHORIZATION'].split(' ').last
      # puts "access_token: ", access_token
      # {"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiJjYzY3MmUzYS1mZTVkLTQ4YjItOTQ4My01ZTYxZDNiNGJjMGEiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYWRtaW4tY2xpIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNTkwYzlhNGUtYzljNC00OTU1LTg1NDAtYTViOTM2ODM5NjEzIiwiYWNyIjoiMSIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwiYWxsb3dlZC1vcmlnaW5zIjpbXSwicmVzb3VyY2VfYWNjZXNzIjp7fSwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.T_GB_kBtZk-gmFNJ5rC2sJpNl4V3TUyhixq76hOi5MbgDbo_FfuKRomxviAeQi-RdJPIEffdzrVmaYXZVQHufpaYx9p90GQd3THQWMyZD50zMY40j-XlungaGKjizWNxaywvGXBMvDE_qYp0hr4Uewm4evO_NRRI1bWQLeaeJ3oHr1_p9vFZf5Kh8tZYR-dQSWuESvHhZrJAqHTzXlYYMRBqfjDyAgUhm8QbbtmDtPr0kkkIh1TmXevkZbm91mrS-9jWrS4zGZE5LiT5KdWnMs9P8FBR1p3vywwIu_z-0MF8_DIMJWa7ApZAXjtrszXAYVfCKsaisjjD9HacgpE-4w","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiIyOTRmZjc5Yy01ZWIxLTQwNDgtYmM1NS03NjcwOGU1Njg1YzMiLCJleHAiOjE0NzY0NDYwOTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImFkbWluLWNsaSIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjU5MGM5YTRlLWM5YzQtNDk1NS04NTQwLWE1YjkzNjgzOTYxMyIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwicmVzb3VyY2VfYWNjZXNzIjp7fX0.WGHvTiVc08xuVCDM5YLlvIzvBgz0aJ3OY3-VGmKSyI-fDLfbp9LSLkPsIqiKO9mDjybSfEkrNmPBd60lWecUC43DacVhVbiLEU9cJdMnjQjrU0P3wg1HFQmcG8exylJMzWoAbJzm893SP-kgKVYCnbQ55Os1-oT1ClHr3Ts6BHVgz5FWrc3dk6DqOrGAxmoJLQUgNJ5jdF-udt-j81OcBTtC3b-RXFXlRu3AyJ0p-UPiu4_HkKBVdg0pmycuN0v0it-TxR_mlM9lhvdVMGXLD9_-PUgklfc6XisdCrGa_b9r06aQCiekXGWptLoFF1Oz__g2_v4Gsrzla5YKBZzGfA","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiI5NWVmMGY0Yi1lODIyLTQwMTAtYWU1NS05N2YyYTEzZWViMzkiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiSUQiLCJhenAiOiJhZG1pbi1jbGkiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI1OTBjOWE0ZS1jOWM0LTQ5NTUtODU0MC1hNWI5MzY4Mzk2MTMiLCJhY3IiOiIxIiwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.FrwYdv1S8mqivHjsyA93ycl10z2tisVJraUGcBJzle060nCO69ZEa0fzrMMCbSkjY1JAwjP92d7_ixuWpcUVvQLkesxKOgcBc8LVhClyh3__8p46kIwfrJYMZQt0cJ6f6nASX1yaySE9sDgl3ElkW0vz-i9vhEXkIh6m-EuC7lH0ZIIL-39-occssq7G5hDleDUMThno8sEsl8rgtV-GdAfjKIwi-yOB0X8K1RrfDarccwA3XB0R8nHAbInZGsrF114KsBuaEvWjKki4m86xFkfPPuSlvWaVRtCziiTBqrBZ_Qna6wI9FfAOiTzPXE5AfFtDowih6d-26kT_jd_7GA","not-before-policy":0,"session_state":"590c9a4e-c9c4-4955-8540-a5b936839613"}

      parsed_res, code = parse_json(res.body)
      @access_token = parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED -> FAKE"# , parsed_res['access_token']
    else
      halt 401, "ERROR: ACCESS DENIED!"
    end

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


    # user_results = User.find(nil, filters = {:where => "{\"email\":\"#{@email}\"}" })
    # puts "USER?", user_results.count
    # halt 401, "Your email address is not unique. Exploding into a million pieces!" if user_results.count != 1
    # halt 401, "Your email address is not unique. Exploding into a million pieces!" if user_results.count != 1
    # @user = user_results.first
    # array = []
    # array << { :name => 'test01', :id => 'test', :email => @email }
    @sections = [Sections.new(@usrname, @id, @email)]
    # puts "HERE", @sections.first.name.to_s
    puts "USER ADDED!"
    @access_token
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
    #TODO: Implement
    #Requirement: pre-defined SONATA Realm json template:
    # ./standalone.sh -Dkeycloak.migration.action=export -Dkeycloak.migration.provider=singleFile -Dkeycloak.migration.file=</path/to/template.json>
    #Then, import template into Keycloak thorugh REST API:
    #Imports a realm from a full representation of that realm.
    #POST /admin/realms
    #BodyParameter = JSON representation of the realm
  end

  def set_adapter_client()
    #TODO: Implement
    #Create a new client

    # set Client's client_id must be unique!
    # generate uuid client secret -> call set_adapter_client_credentials()
    #import pre-made Adapter client template
    # set client secret in template
    #POST /admin/realms/{realm}/clients
    #BodyParameter = ClientRepresentation
    #realm = realm name (not id!)
  end

  def set_adapter_client_credentials()
    #TODO: Implement
    #generate uuid
    #save generated uuid secret in config/keycloak.yml
    conf = YAML::load_file('../config/keycloak.yml') #Load
    conf['client'] = 'adapter' #Modify
    conf['secret'] = '' #Modify
    # conf['secret'] = ''
    File.open('../config/keycloak.yml', 'w') {|f| f.write conf.to_yaml } #Store
    #client: adapter
    #secret: <generated uuid>
    # return uuid to set_adapter_client()
  end

  def get_client_secret()
    realm = "master"
    id = "adapter"
    #Get the client secret
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
    #Generate a new secret for the client
    #POST /admin/realms/{realm}/clients/{id}/client-secret
  end

  def set_keycloak_credentials()
    #TODO: Implement
    #Other Keycloak credentials that might be configured
  end

#Comment about ROLES
=begin
Large number of roles approach will quickly become unmanageable and it
may be better of using an ACL or something in the application itself.

It is more often implemented as ACLs rather than RBAC.
RBAC is usually used for things like 'manager' has read/write access to a
group of resources, rather than 'user-a' has read access to 'resource-a'.
=end
end

def create_public_key
  # turn keycloak realm pub key into an actual openssl compat pub key.
  keycloak_yml = YAML.load_file('config/keycloak.yml')
  keycloak_config = JSON.parse(File.read('config/keycloak.json'))
  @s = "-----BEGIN PUBLIC KEY-----\n"
  @s += keycloak_yml['realm_public_key'].scan(/.{1,64}/).join("\n")
  @s += "\n-----END PUBLIC KEY-----\n"
  @key = OpenSSL::PKey::RSA.new @s
  set :keycloak_pub_key, @key
  set :keycloak_client_id, keycloak_config['resource']
  set :keycloak_url, keycloak_config['auth-server-url'] + '/' + keycloak_config['realm'] + '/'

  # Print token settings
  # puts "settings.keycloak_pub_key: ", settings.keycloak_pub_key
end