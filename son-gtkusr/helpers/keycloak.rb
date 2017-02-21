require 'json'
require 'sinatra'
require 'yaml'
require 'net/http'
require 'base64'
require 'jwt'
require 'uri'
# require 'openssl'

def parse_json(message)
  # Check JSON message format
  begin
    parsed_message = JSON.parse(message)
  rescue JSON::ParserError => e
    # If JSON not valid, return with errors
    return message, e.to_s + "\n"
  end
  return parsed_message, nil
end

class Keycloak < Sinatra::Application

  # logger.info "Adapter: Starting configuration"
  # Load configurations
  keycloak_config = YAML.load_file 'config/keycloak.yml'

  # Load authorization mappings
  @@auth_mappings = YAML.load_file 'config/mappings.yml'

  puts "MAPPINGS CONTENT", @@auth_mappings

  # p keycloak_config
  # p "ISSUER", ENV['JWT_ISSUER']
  @@address = keycloak_config['address']
  @@port = keycloak_config['port']
  @@uri = keycloak_config['uri']
  @@realm_name = keycloak_config['realm']
  @@client_name = keycloak_config['client']
  @@client_secret = keycloak_config['secret']

  def self.get_oidc_endpoints
    # Call http://localhost:8081/auth/realms/master/.well-known/openid-configuration to obtain endpoints
    url = URI.parse("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/.well-known/openid-configuration")

    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)

    response = http.request(request)
    # puts response.read_body # <-- save endpoints file
    File.open('config/endpoints.json', 'w') do |f|
      f.puts response.read_body
    end
  end

  def self.get_adapter_install_json
    # Get client (Adapter) registration configuration
    # 'http://localhost:8081/auth/realms/master/clients-registrations/openid-connect'
    # Avoid using hardcoded authorization - > # http://localhost:8081/auth/realms/master/?

    #url = URI("http://127.0.0.1:8081/auth/realms/master/clients-registrations/install/adapter")
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/clients-registrations/install/adapter")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Get.new(url.to_s)
    request.basic_auth(@@client_name.to_s, @@client_secret.to_s)
    request["content-type"] = 'application/json'

    response = http.request(request)
    p "RESPONSE", response
    p "RESPONSE.read_body222", response.read_body
    # puts response.read_body # <-- save endpoints file
    File.open('config/keycloak.json', 'w') do |f|
      f.puts response.read_body
    end
  end

  def self.get_adapter_token
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/protocol/openid-connect/token")
    #http = Net::HTTP.new(url.host, url.port)

    #request = Net::HTTP::Post.new(url.to_s)
    #request.basic_auth(@client_name.to_s, @client_secret.to_s)
    #request["content-type"] = 'application/json'
    #body = {"username" => "admin",
    #        "credentials" => [
    #            {"type" => "client_credentials",
    #             "value" => "admin"}]}
    #request.body = body.to_json

    res = Net::HTTP.post_form(url, 'client_id' => @@client_name, 'client_secret' => @@client_secret,
                              'username' => "admin",
                              'password' => "admin",
                              'grant_type' => "client_credentials")

    #res = http.request(request)

    #p "RESPONSE", res
    #p "RESPONSE.read_body333", res.read_body

    parsed_res, code = parse_json(res.body)

    if parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED", parsed_res['access_token']

      File.open('config/token.json', 'w') do |f|
        f.puts parsed_res['access_token']
      end
      #@access_token = parsed_res['access_token']
      parsed_res['access_token']
    end
  end

      # Policies
  OK = Proc.new { halt 200 }
  FORBIDDEN = Proc.new {
    halt 401 unless is_loggedin?(user)
    halt 403
  }
  LOGGEDIN = Proc.new { halt 401 unless is_loggedin?(user) }


  def decode_token(token, keycloak_pub_key)
    begin
      decoded_payload, decoded_header = JWT.decode token, keycloak_pub_key, true, { :algorithm => 'RS256' }
      puts "DECODED_HEADER: ", decoded_header
      puts "DECODED_PAYLOAD: ", decoded_payload
      return decoded_payload, decoded_header
    # Handle expired token, e.g. logout user or deny access
    rescue JWT::DecodeError
      json_error(401, 'A token must be passed')
    rescue JWT::ExpiredSignature
      json_error(403, 'The token has expired')
    rescue JWT::InvalidIssuerError
      json_error(403, 'The token does not have a valid issuer')
    rescue JWT::InvalidIatError
      json_error(403, 'The token does not have a valid "issued at" time')
    end
  end

  def get_public_key
    # turn keycloak realm pub key into an actual openssl compat pub key.
    keycloak_config = JSON.parse(File.read('../config/keycloak.json'))
    @s = "-----BEGIN PUBLIC KEY-----\n"
    @s += keycloak_config['realm-public-key'].scan(/.{1,64}/).join("\n")
    @s += "\n-----END PUBLIC KEY-----\n"
    @key = OpenSSL::PKey::RSA.new @s
    keycloak_pub_key = @key
  end

  # Public key used by realm encoded as a JSON Web Key (JWK).
  # This key can be used to verify tokens issued by Keycloak without making invocations to the server.
  def jwk_certs(realm=nil)
    http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/certs"
    url = URI(http_path)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)
    response = http.request(request)
    puts "RESPONSE", response.read_body
    response_json = parse_json(response.read_body)[0]
  end

  # "userinfo_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/userinfo"
  def userinfo(token)
    # token = @@access_token
    puts "TOKEN_CONTENT", token
    http_path = "http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/protocol/openid-connect/userinfo"
    url = URI(http_path)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)
    request["authorization"] = 'bearer ' + token
    response = http.request(request)
    puts "RESPONSE", response.read_body
    # response_json = parse_json(response.read_body)[0]
    response.body
  end

  # Token Validation Endpoint
  # "token_introspection_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/token/introspect"
  def token_validation(token, realm=nil)
    # puts "TEST ACCESS_TOKEN", token
    # decode_token(token, keycloak_pub_key)
    # url = URI("http://localhost:8081/auth/realms/master/clients-registrations/openid-connect/")
    url = URI("http://127.0.0.1:8081/auth/realms/master/protocol/openid-connect/token/introspect")
    # ttp = Net::HTTP.new(url.host, url.port)

    # request = Net::HTTP::Post.new(url.to_s)
    # request = Net::HTTP::Get.new(url.to_s)
    # request["authorization"] = 'bearer ' + token
    # request["content-type"] = 'application/json'
    # body = {"token" => token}

    # request.body = body.to_json

    res = Net::HTTP.post_form(url, 'client_id' => 'adapter',
                              'client_secret' => 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f',
                              'grant_type' => 'client_credentials', 'token' => token)

    puts "RESPONSE_INTROSPECT", res.read_body
    puts "CODE_INTROSPECT", res.code
    # RESPONSE_INTROSPECT:
    # {"jti":"bc1200e5-3b6d-43f2-a125-dc4ed45c7ced","exp":1486105972,"nbf":0,"iat":1486051972,"iss":"http://localhost:8081/auth/realms/master","aud":"adapter","sub":"67cdf213-349b-4539-bdb2-43351bf3f56e","typ":"Bearer","azp":"adapter","auth_time":0,"session_state":"608a2a72-198d-440b-986f-ddf37883c802","name":"","preferred_username":"service-account-adapter","email":"service-account-adapter@placeholder.org","acr":"1","client_session":"2c31bbd9-c13d-43f1-bb30-d9bd46e3c0ab","allowed-origins":[],"realm_access":{"roles":["create-realm","admin","uma_authorization"]},"resource_access":{"adapter":{"roles":["uma_protection"]},"master-realm":{"roles":["view-identity-providers","view-realm","manage-identity-providers","impersonation","create-client","manage-users","view-authorization","manage-events","manage-realm","view-events","view-users","view-clients","manage-authorization","manage-clients"]},"account":{"roles":["manage-account","view-profile"]}},"clientHost":"127.0.0.1","clientId":"adapter","clientAddress":"127.0.0.1","client_id":"adapter","username":"service-account-adapter","active":true}
    return res.body, res.code
  end

  def register_user(token, user_form) #, username,firstname, lastname, email, credentials)
    # schema = {"username" => "tester",
    #         "enabled" => true,
    #         "totp" => false,
    #         "emailVerified" => false,
    #         "firstName" => "User",
    #         "lastName" => "Sample",
    #         "email" => "tester.sample@email.com.br",
    #         "credentials" => [
    #             {"type" => "password",
    #              "value" => "1234"}
    #         ],
    #         "requiredActions" => [],
    #         "federatedIdentities" => [],
    #         "attributes" => {"tester" => ["true"],"admin" => ["false"]},
    #         "realmRoles" => [],
    #         "clientRoles" => {},
    #         "groups" => []}

    token = @@access_token
    puts "REGISTER_USER ACCESS_TOKEN_CONTENT", token
    body = user_form

    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/admin/realms/#{@@realm_name}/users")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url.to_s)
    request["authorization"] = 'Bearer ' + token
    request["content-type"] = 'application/json'
    request.body = body.to_json
    response = http.request(request)
    puts "REG CODE", response.code
    puts "REG BODY", response.body
    if response.code.to_i != 201
      halt response.code.to_i, response.body.to_s
    end


    #GET new registered user Id
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/admin/realms/#{@@realm_name}/users?username=#{user_form['username']}")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Get.new(url.to_s)
    request["authorization"] = 'Bearer ' + token
    request.body = body.to_json

    response = http.request(request)
    puts "ID CODE", response.code
    puts "ID BODY", response.body
    user_id = parse_json(response.body).first[0]["id"]
    puts "USER ID", user_id

    #- Use the endpoint to setup temporary password of user (It will
    #automatically add requiredAction for UPDATE_PASSWORD
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/admin/realms/#{@@realm_name}/users/#{user_id}/reset-password")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Put.new(url.to_s)
    request["authorization"] = 'Bearer ' + token
    request["content-type"] = 'application/json'

    # credentials = user_form['credentials']

    credentials = {"type" => "password",
                   "value" => "1234",
                   "temporary" => "false"}

    request.body = credentials.to_json
    response = http.request(request)
    puts "CRED CODE", response.code
    puts "CRED BODY", response.body
    if response.code.to_i != 204
      halt response.code.to_i, response.body.to_s
    end

    #- Then use the endpoint for update user and send the empty array of
    #requiredActions in it. This will ensure that UPDATE_PASSWORD required
    #action will be deleted and user won't need to update password again.
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/admin/realms/#{@@realm_name}/users/#{user_id}")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Put.new(url.to_s)
    request["authorization"] = 'Bearer ' + token
    request["content-type"] = 'application/json'

    body = {"requiredActions" => []}

    request.body = body.to_json
    response = http.request(request)
    puts "UPD CODE", response.code
    puts "UPD BODY", response.body
    if response.code.to_i != 204
      halt response.code.to_i, response.body.to_s
    end
    halt 201
  end

  # "registration_endpoint":"http://localhost:8081/auth/realms/master/clients-registrations/openid-connect"
  def register_client (token, keycloak_pub_key, realm=nil)
    puts "TEST ACCESS_TOKEN", token
    decode_token(token, keycloak_pub_key)
    url = URI("http://localhost:8081/auth/realms/master/clients-registrations/openid-connect/")
    #url = URI("http://127.0.0.1:8081/auth/realms/master/protocol/openid-connect/token/introspect")
    #url = URI("http://127.0.0.1:8081/auth/realms/master/protocol/openid-connect/userinfo")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url.to_s)
    #request = Net::HTTP::Get.new(url.to_s)
    request["authorization"] = 'bearer ' + token
    request["content-type"] = 'application/json'
    body = {"client_name" => "myclient",
            "client_secret" => "1234-admin"}

    request.body = body.to_json

    response = http.request(request)
    puts "RESPONSE", response.read_body
    response_json = parse_json(response.read_body)[0]

    @reg_uri = response_json['registration_client_uri']
    @reg_token = response_json['registration_access_token']
    @reg_id = response_json['client_id']
    @reg_secret = response_json['client_secret']
  end

  # "token_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
  def login_admin()
    @@address = 'localhost'
    @port = '8081'
    @uri = 'auth'
    @client_name = 'adapter'
    @client_secret = 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f'
    @access_token = nil

    url = URI('http://' + @@address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/protocol/openid-connect/token')

    res = Net::HTTP.post_form(url, 'client_id' => @client_name, 'client_secret' => @client_secret,
                              #                            'username' => "user",
                              #                            'password' => "1234",
                              'grant_type' => "client_credentials")

    if res.body['access_token']
      parsed_res, code = parse_json(res.body)
      @access_token = parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED" , parsed_res['access_token']
      parsed_res['access_token']
    end
  end

  # "token_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
  def login_user_broker
    # curl -d "client_id=admin-cli" -d "username=user1" -d "password=1234" -d "grant_type=password" "http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token"
    client_id = "adapter"
    @usrname = "user"
    pwd = "1234"
    grt_type = "password"
    http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
    idp_path = "http://localhost:8081/auth/realms/master/broker/github/login?"
    # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

    uri = URI(http_path)
    # uri = URI(idp_path)
    res = Net::HTTP.post_form(uri, 'client_id' => client_id, 'client_secret' => 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f',
                              'username' => @usrname,
                              'password' => pwd,
                              'grant_type' => grt_type)
    puts "RES.BODY: ", res.body


    if res.body['access_token']
      #if env['HTTP_AUTHORIZATION']
      # puts "env: ", env['HTTP_AUTHORIZATION']
      # access_token = env['HTTP_AUTHORIZATION'].split(' ').last
      # puts "access_token: ", access_token
      # {"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiJjYzY3MmUzYS1mZTVkLTQ4YjItOTQ4My01ZTYxZDNiNGJjMGEiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYWRtaW4tY2xpIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNTkwYzlhNGUtYzljNC00OTU1LTg1NDAtYTViOTM2ODM5NjEzIiwiYWNyIjoiMSIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwiYWxsb3dlZC1vcmlnaW5zIjpbXSwicmVzb3VyY2VfYWNjZXNzIjp7fSwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.T_GB_kBtZk-gmFNJ5rC2sJpNl4V3TUyhixq76hOi5MbgDbo_FfuKRomxviAeQi-RdJPIEffdzrVmaYXZVQHufpaYx9p90GQd3THQWMyZD50zMY40j-XlungaGKjizWNxaywvGXBMvDE_qYp0hr4Uewm4evO_NRRI1bWQLeaeJ3oHr1_p9vFZf5Kh8tZYR-dQSWuESvHhZrJAqHTzXlYYMRBqfjDyAgUhm8QbbtmDtPr0kkkIh1TmXevkZbm91mrS-9jWrS4zGZE5LiT5KdWnMs9P8FBR1p3vywwIu_z-0MF8_DIMJWa7ApZAXjtrszXAYVfCKsaisjjD9HacgpE-4w","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiIyOTRmZjc5Yy01ZWIxLTQwNDgtYmM1NS03NjcwOGU1Njg1YzMiLCJleHAiOjE0NzY0NDYwOTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImFkbWluLWNsaSIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjU5MGM5YTRlLWM5YzQtNDk1NS04NTQwLWE1YjkzNjgzOTYxMyIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwicmVzb3VyY2VfYWNjZXNzIjp7fX0.WGHvTiVc08xuVCDM5YLlvIzvBgz0aJ3OY3-VGmKSyI-fDLfbp9LSLkPsIqiKO9mDjybSfEkrNmPBd60lWecUC43DacVhVbiLEU9cJdMnjQjrU0P3wg1HFQmcG8exylJMzWoAbJzm893SP-kgKVYCnbQ55Os1-oT1ClHr3Ts6BHVgz5FWrc3dk6DqOrGAxmoJLQUgNJ5jdF-udt-j81OcBTtC3b-RXFXlRu3AyJ0p-UPiu4_HkKBVdg0pmycuN0v0it-TxR_mlM9lhvdVMGXLD9_-PUgklfc6XisdCrGa_b9r06aQCiekXGWptLoFF1Oz__g2_v4Gsrzla5YKBZzGfA","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiI5NWVmMGY0Yi1lODIyLTQwMTAtYWU1NS05N2YyYTEzZWViMzkiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiSUQiLCJhenAiOiJhZG1pbi1jbGkiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI1OTBjOWE0ZS1jOWM0LTQ5NTUtODU0MC1hNWI5MzY4Mzk2MTMiLCJhY3IiOiIxIiwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.FrwYdv1S8mqivHjsyA93ycl10z2tisVJraUGcBJzle060nCO69ZEa0fzrMMCbSkjY1JAwjP92d7_ixuWpcUVvQLkesxKOgcBc8LVhClyh3__8p46kIwfrJYMZQt0cJ6f6nASX1yaySE9sDgl3ElkW0vz-i9vhEXkIh6m-EuC7lH0ZIIL-39-occssq7G5hDleDUMThno8sEsl8rgtV-GdAfjKIwi-yOB0X8K1RrfDarccwA3XB0R8nHAbInZGsrF114KsBuaEvWjKki4m86xFkfPPuSlvWaVRtCziiTBqrBZ_Qna6wI9FfAOiTzPXE5AfFtDowih6d-26kT_jd_7GA","not-before-policy":0,"session_state":"590c9a4e-c9c4-4955-8540-a5b936839613"}

      parsed_res, code = parse_json(res.body)
      @access_token = parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED", parsed_res['access_token']
      parsed_res['access_token']
    else
      401
    end
  end

  def login_user (username=nil, credentials=nil)
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/realms/#{@@realm_name}/protocol/openid-connect/token")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(url.to_s)
    request["authorization"] = 'Bearer ' + @@access_token
    request["content-type"] = 'application/x-www-form-urlencoded'

    p "@client_name", @@client_name
    p "@client_secret", @@client_secret

    request.set_form_data({'client_id' => @@client_name,
                           'client_secret' => @@client_secret,
                           'username' => username.to_s,
                           'password' => credentials['value'],
                           'grant_type' => credentials['type']})

    response = http.request(request)
    puts "LOG CODE", response.code
    puts "LOG BODY", response.body

    unless response.code == '200'
      halt response.code.to_i, response.body
    end

    #parsed_res = parse_json(response.body)
    #p "RESPONSE BODY"
    #puts parsed_res[0]['access_token']
    #halt 200, parsed_res['access_token'].to_json
    halt 200, response.body
  end

  # "token_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
  def login_client
    # curl -d "client_id=admin-cli" -d "username=user1" -d "password=1234" -d "grant_type=password" "http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token"
    http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/token"
    # auth = "Basic YWRhcHRlcjpkZjdlODE2ZC0wMzM3LTRmYmUtYTNmNC03YjUyNjNlYWJhOWY=\n"
    # puts `curl -X POST --data "client_id=#{client_id}&username=#{usrname}"&password=#{pwd}&grant_type=#{grt_type} #{http_path}`

    uri = URI(http_path)

    res = Net::HTTP.post_form(uri, 'client_id' => 'adapter',
                              'client_secret' => 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f',
                              'grant_type' => 'client_credentials'
    )

    puts "RES.HEADER: ", res.header
    puts "RES.BODY: ", res.body


    if res.body['access_token']
      #if env['HTTP_AUTHORIZATION']
      # puts "env: ", env['HTTP_AUTHORIZATION']
      # access_token = env['HTTP_AUTHORIZATION'].split(' ').last
      # puts "access_token: ", access_token
      # {"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiJjYzY3MmUzYS1mZTVkLTQ4YjItOTQ4My01ZTYxZDNiNGJjMGEiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYWRtaW4tY2xpIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNTkwYzlhNGUtYzljNC00OTU1LTg1NDAtYTViOTM2ODM5NjEzIiwiYWNyIjoiMSIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwiYWxsb3dlZC1vcmlnaW5zIjpbXSwicmVzb3VyY2VfYWNjZXNzIjp7fSwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.T_GB_kBtZk-gmFNJ5rC2sJpNl4V3TUyhixq76hOi5MbgDbo_FfuKRomxviAeQi-RdJPIEffdzrVmaYXZVQHufpaYx9p90GQd3THQWMyZD50zMY40j-XlungaGKjizWNxaywvGXBMvDE_qYp0hr4Uewm4evO_NRRI1bWQLeaeJ3oHr1_p9vFZf5Kh8tZYR-dQSWuESvHhZrJAqHTzXlYYMRBqfjDyAgUhm8QbbtmDtPr0kkkIh1TmXevkZbm91mrS-9jWrS4zGZE5LiT5KdWnMs9P8FBR1p3vywwIu_z-0MF8_DIMJWa7ApZAXjtrszXAYVfCKsaisjjD9HacgpE-4w","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiIyOTRmZjc5Yy01ZWIxLTQwNDgtYmM1NS03NjcwOGU1Njg1YzMiLCJleHAiOjE0NzY0NDYwOTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiUmVmcmVzaCIsImF6cCI6ImFkbWluLWNsaSIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjU5MGM5YTRlLWM5YzQtNDk1NS04NTQwLWE1YjkzNjgzOTYxMyIsImNsaWVudF9zZXNzaW9uIjoiYjhkODI4ZjAtNWQ3Yy00NjI4LWEzOTEtNGQwNTY0MDNkNTRjIiwicmVzb3VyY2VfYWNjZXNzIjp7fX0.WGHvTiVc08xuVCDM5YLlvIzvBgz0aJ3OY3-VGmKSyI-fDLfbp9LSLkPsIqiKO9mDjybSfEkrNmPBd60lWecUC43DacVhVbiLEU9cJdMnjQjrU0P3wg1HFQmcG8exylJMzWoAbJzm893SP-kgKVYCnbQ55Os1-oT1ClHr3Ts6BHVgz5FWrc3dk6DqOrGAxmoJLQUgNJ5jdF-udt-j81OcBTtC3b-RXFXlRu3AyJ0p-UPiu4_HkKBVdg0pmycuN0v0it-TxR_mlM9lhvdVMGXLD9_-PUgklfc6XisdCrGa_b9r06aQCiekXGWptLoFF1Oz__g2_v4Gsrzla5YKBZzGfA","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIyRG1CZm1UaEJEa3NmNElMWVFnVEpSVmNRMDZJWEZYdWNOMzhVWk1rQ0cwIn0.eyJqdGkiOiI5NWVmMGY0Yi1lODIyLTQwMTAtYWU1NS05N2YyYTEzZWViMzkiLCJleHAiOjE0NzY0NDQ1OTAsIm5iZiI6MCwiaWF0IjoxNDc2NDQ0MjkwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvU09OQVRBIiwiYXVkIjoiYWRtaW4tY2xpIiwic3ViIjoiYjFiY2M4YmQtOTJhMy00N2RkLTliOGUtZDY3NGQ2ZTU0ZjJjIiwidHlwIjoiSUQiLCJhenAiOiJhZG1pbi1jbGkiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI1OTBjOWE0ZS1jOWM0LTQ5NTUtODU0MC1hNWI5MzY4Mzk2MTMiLCJhY3IiOiIxIiwibmFtZSI6InNvbmF0YSB1c2VyIHNvbmF0YSB1c2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlcjEiLCJnaXZlbl9uYW1lIjoic29uYXRhIHVzZXIiLCJmYW1pbHlfbmFtZSI6InNvbmF0YSB1c2VyIiwiZW1haWwiOiJzb25hdGF1c2VyQHNvbmF0YS5uZXQifQ.FrwYdv1S8mqivHjsyA93ycl10z2tisVJraUGcBJzle060nCO69ZEa0fzrMMCbSkjY1JAwjP92d7_ixuWpcUVvQLkesxKOgcBc8LVhClyh3__8p46kIwfrJYMZQt0cJ6f6nASX1yaySE9sDgl3ElkW0vz-i9vhEXkIh6m-EuC7lH0ZIIL-39-occssq7G5hDleDUMThno8sEsl8rgtV-GdAfjKIwi-yOB0X8K1RrfDarccwA3XB0R8nHAbInZGsrF114KsBuaEvWjKki4m86xFkfPPuSlvWaVRtCziiTBqrBZ_Qna6wI9FfAOiTzPXE5AfFtDowih6d-26kT_jd_7GA","not-before-policy":0,"session_state":"590c9a4e-c9c4-4955-8540-a5b936839613"}

      parsed_res, code = parse_json(res.body)
      @access_token = parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED", parsed_res['access_token']
      parsed_res['access_token']
    else
      401
    end
  end

  # Method that allows end-user authentication through authorized browser
  # "authorization_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/auth"
  def authorize_browser(token=nil, realm=nil)
    client_id = "adapter"
    @usrname = "user"
    pwd = "1234"
    grt_type = "password"

    query = "response_type=code&scope=openid%20profile&client_id=adapter&redirect_uri=http://127.0.0.1/"
    http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/auth" + "?" + query
    url = URI(http_path)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)
    #request["authorization"] = 'bearer ' + token

    response = http.request(request)
    # p "RESPONSE", response.body

    File.open('codeflow.html', 'wb') do |f|
      f.puts response.read_body
    end
  end

  # "end_session_endpoint":"http://localhost:8081/auth/realms/master/protocol/openid-connect/logout"
  def logout(user_token, user=nil, realm=nil)
    # user = token['sub']#'971fc827-6401-434e-8ea0-5b0f6d33cb41'
    user = parse_json(userinfo(user_token))[0]
    p "SUB[0]", user['sub']
    # http_path = "http://localhost:8081/auth/realms/master/protocol/openid-connect/logout"
    http_path ="http://localhost:8081/auth/admin/realms/master/users/#{user['sub']}/logout"
    url = URI(http_path)
    http = Net::HTTP.new(url.host, url.port)
    # request = Net::HTTP::Post.new(url.to_s)
    request = Net::HTTP::Post.new(url.to_s)
    request["authorization"] = 'bearer ' + @@access_token
    request["content-type"] = 'application/x-www-form-urlencoded'
    #request["content-type"] = 'application/json'

    #request.set_form_data({'client_id' => 'adapter',
    #                       'client_secret' => 'df7e816d-0337-4fbe-a3f4-7b5263eaba9f',
    #                       'username' => 'user',
    #                       'password' => '1234',
    #                       'grant_type' => 'password'})
    #request.set_form_data('refresh_token' => token)

    #_remove_all_user_sessions_associated_with_the_user

    #request.body = body.to_json

    response = http.request(request)
    puts "RESPONSE CODE", response.code
    # puts "RESPONSE BODY", response.body
    #response_json = parse_json(response.read_body)[0]
    halt response.code.to_i
  end

  def authenticate
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
      parsed_res, code = parse_json(res.body)
      @access_token = parsed_res['id_token']
      puts "ID_TOKEN RECEIVED"# , parsed_res['access_token']
    else
      halt 401, "ERROR: ACCESS DENIED!"
    end
  end

  def authorize?(user_token, request)
    #=> Check token!
    public_key = get_public_key
    payload, header = decode_token(user_token, public_key)
    puts "payload", payload
    #=> evaluate request
    #
    #=> Check token roles
=begin
    "realm_access":{
        "roles":[
            "uma_authorization",
            "hello.say"
        ]
    },
        "resource_access":{
        "account":{
            "roles":[
                "manage-account",
                "view-profile"
=end
# scopes?    "scope" : {
#    "realm" : [ "user" ]
#    }

    #=> Response => 20X or 40X
    #
    #
    #
    #
    #
    #
    #
    #
  end

  def refresh
    ###
    #TODO: Implement
    #=> Check if token.expired?
    #=> Then GET new token
  end

  def set_user_roles(token)
    #TODO: Implement
  end

  def update_client()
    #TODO: Implement
    # Update the client
    # PUT /admin/realms/{realm}/clients/{id}
    # Body rep = ClientRepresentation

  end

  def get_role_details(role)
    #url = URI("http://localhost:8081/auth/admin/realms/#{realm}/clients/#{id}/roles/#{role}")
    url = URI("http://#{@@address.to_s}:#{@@port.to_s}/#{@@uri.to_s}/admin/realms/#{@@realm_name}/roles/#{role}")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url.to_s)
    request["authorization"] = 'Bearer ' + @@access_token

    response = http.request(request)
    #p "RESPONSE.read_body", response.read_body
    p "CODE", response.code
    parsed_res, code = parse_json(response.body)
    p "RESPONSE_PARSED", parsed_res
  end

  def is_active?(introspect_res)
    puts "JSON PARSING"
    token_evaluation = JSON.parse(introspect_res)
    puts "token_evaluation", token_evaluation.to_s
    case token_evaluation['active']
      when true
        p "ACTIVE CONTENTS TRUE", token_evaluation['active']
        true
      else
        p "ACTIVE CONTENTS FALSE", token_evaluation['active']
        false
    end
  end

  def resolve_request(uri, method)
    # Parse uri path
    path = URI(uri).path.split('/')[1]
    p "path", path
    # Find mapped resource to path
    resources = @@auth_mappings['resources']
    p "RESOURCES", resources

    resource = nil
    p "PATHS", @@auth_mappings['paths']
    @@auth_mappings['paths'].each { |k, v|
      puts "k, v", k, v
      v.each { |kk, vv|
        puts "kk, vv", kk, vv
        if kk == path
          p "Resource found", k, kk
          resource = [k, kk]
          break
        end
      }
      p "FOUND", resource
      if resource
        break
      end
    }
    unless resource
      json_error(401, 'The resource is not available')
    end

    unless @@auth_mappings['paths'][resource[0]][resource[1]].key?(method)
      json_error(401, 'The resource operation is not available')
    else
      operation = @@auth_mappings['paths'][resource[0]][resource[1]][method]
      puts "OPERATION", operation
      request = {"resource" => resource[0], "type" => resource[1], "operation" => operation}
      #json_error(501, 'OK')
    end
  end
end


# DEPRECATED API - only to apply testings
=begin
  def initialize
    super

    # Read users-rights from a datasource
    @accounts = {
        user1: [{'Service' => 'PERMISSION'}],}
  end

  def process_request (req, scope)
    scopes, user = req.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?(scope) && @accounts.has_key?(username)
      yield req, username
    else
      halt 403
    end
  end
end
=end