require 'json'
require 'sinatra'
require 'yaml'
require 'net/http'
require 'base64'
# require 'openssl'
# require 'yaml'

class Keycloak < Sinatra::Application

  # Load configurations
  keycloak_config = YAML.load_file 'config/keycloak.yml'

  # p keycloak_config
  # p "ISSUER", ENV['JWT_ISSUER']

  @address = keycloak_config['address']
  @port = keycloak_config['port']
  @uri = keycloak_config['uri']
  @client_name = keycloak_config['realm']
  @client_secret = keycloak_config['secret'] # Maybe change to CERT
  @access_token = nil

  # Call http://localhost:8081/auth/realms/master/.well-known/openid-configuration to obtain endpoints
  url = URI.parse('http://' + @address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/.well-known/openid-configuration')

  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.to_s)

  response = http.request(request)
  # puts response.read_body # <-- save endpoints file
  File.open('config/endpoints.json', 'w') do |f|
    f.puts response.read_body
  end

  # Get client (Adapter) registration configuration
  # 'http://localhost:8081/auth/realms/master/clients-registrations/openid-connect'
  # Avoid using hardcoded authorization - > # http://localhost:8081/auth/realms/master/?

  #url = URI("http://127.0.0.1:8081/auth/realms/master/clients-registrations/install/adapter")
  url = URI('http://' + @address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/clients-registrations/install/adapter')
  http = Net::HTTP.new(url.host, url.port)

  request = Net::HTTP::Get.new(url.to_s)
  request.basic_auth(@client_name.to_s, @client_secret.to_s)
  request["content-type"] = 'application/json'

  response = http.request(request)
  p "RESPONSE", response
  p "RESPONSE.read_body222", response.read_body
  # puts response.read_body # <-- save endpoints file
  File.open('config/keycloak.json', 'w') do |f|
    f.puts response.read_body
  end

  url = URI('http://' + @address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/protocol/openid-connect/token')
  #http = Net::HTTP.new(url.host, url.port)

  #request = Net::HTTP::Post.new(url.to_s)
  #request.basic_auth(@client_name.to_s, @client_secret.to_s)
  #request["content-type"] = 'application/json'
  #body = {"username" => "admin",
  #        "credentials" => [
  #            {"type" => "client_credentials",
  #             "value" => "admin"}]}
  #request.body = body.to_json

  res = Net::HTTP.post_form(url, 'client_id' => @client_name, 'client_secret' => @client_secret,
                            'username' => "admin",
                            'password' => "admin",
                            'grant_type' => "client_credentials")

  #res = http.request(request)

  p "RESPONSE", res
  p "RESPONSE.read_body333", res.read_body

  if res.body['access_token']
    parsed_res, code = parse_json(res.body)
    @access_token = parsed_res['access_token']
    puts "ACCESS_TOKEN RECEIVED"# , parsed_res['access_token']

    File.open('config/token.json', 'w') do |f|
      f.puts @access_token
    end
  end

  def registration (username,firstname, lastname, email, credentials)
    body = {"username" => "User.Sample",
            "enabled" => true,
            "totp" => false,
            "emailVerified" => false,
            "firstName" => "User",
            "lastName" => "Sample",
            "email" => "user.sample at email.com.br",
            "credentials" => [
                {"type" => "password",
                 "value" => "myPassword"}
            ]
    }

    url = URI("http://localhost:8081/auth/admin/realms/master/users")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url.to_s)
    # TODO: Add admin token access
    request["authorization"] = 'Bearer ' + @access_token.to_s

    request["content-type"] = 'application/json'
    request.body = body.to_json

    response = http.request(request)
    puts response.read_body
  end

  def login (username, credentials)
    body = {"username" => "user.sample",
            "credentials" => [
                {"type" => "password",
                 "value" => "1234"}
            ]
    }

    url = URI("http://localhost:8081/auth/realms/master/protocol/openid-connect/token")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url.to_s)
    # TODO: Add admin token access
    request["authorization"] = 'Bearer ' + @access_token.to_s

    request["content-type"] = 'application/json'
    request.body = body.to_json

    response = http.request(request)
    puts response.read_body

  end

  def logout

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
      @access_token = parsed_res['access_token']
      puts "ACCESS_TOKEN RECEIVED"# , parsed_res['access_token']
    else
      halt 401, "ERROR: ACCESS DENIED!"
    end
  end

  def authorize

  end

  def refresh

  end
end