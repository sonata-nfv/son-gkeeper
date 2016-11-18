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
  @reg_token = keycloak_config['token'] # Maybe change to CERT

  # Call http://localhost:8081/auth/realms/master/.well-known/openid-configuration to obtain endpoints
  url = URI.parse('http://' + @address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/.well-known/openid-configuration')

  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.to_s)

  response = http.request(request)
  # puts response.read_body # <-- save endpoints file

  # Get client (Adapter) registration configuration
  # 'http://localhost:8081/auth/realms/master/clients-registrations/openid-connect'
  # Avoid using hardcoded authorization - > # http://localhost:8081/auth/realms/master/?

  #url = URI("http://127.0.0.1:8081/auth/realms/master/clients-registrations/install/adapter")
  url = URI('http://' + @address.to_s + ':' + @port.to_s + '/' + @uri.to_s + '/realms/master/clients-registrations/install/adapter')
  http = Net::HTTP.new(url.host, url.port)

  request = Net::HTTP::Get.new(url.to_s)
  request.basic_auth("adapter", "df7e816d-0337-4fbe-a3f4-7b5263eaba9f")
  request["content-type"] = 'application/json'

  response = http.request(request)
  p "RESPONSE", response
  p "RESPONSE.read_body", response.read_body

  @access_token = nil

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
    request["authorization"] = 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJqZjQ3WXlHSzQ3VUprLXJ1cUk5RV9IaDhsNS1heHFrMzkxX0NpUUhmTm9nIn0.eyJqdGkiOiI3ZDBiYzEwNy1iYzViLTQ4YmItYjU3Ny0wYjdjOGIyZGJjOTkiLCJleHAiOjE0NzgyNjc4NDAsIm5iZiI6MCwiaWF0IjoxNDc4MjY2OTQwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvbWFzdGVyIiwiYXVkIjoiYWRhcHRlciIsInN1YiI6IjY3Y2RmMjEzLTM0OWItNDUzOS1iZGIyLTQzMzUxYmYzZjU2ZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkYXB0ZXIiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiJiNzU3MjhkZi1hZTBiLTQxZTAtYjY1Yy00N2QxYmNhZGRhMzAiLCJhY3IiOiIxIiwiY2xpZW50X3Nlc3Npb24iOiI0ZTBmNTYxMy0xNGY5LTRmYWEtOWEwMS02YTgyOWYwMGQ5ODQiLCJhbGxvd2VkLW9yaWdpbnMiOltdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiY3JlYXRlLXJlYWxtIiwiYWRtaW4iLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFkYXB0ZXIiOnsicm9sZXMiOlsidW1hX3Byb3RlY3Rpb24iXX0sIm1hc3Rlci1yZWFsbSI6eyJyb2xlcyI6WyJ2aWV3LWlkZW50aXR5LXByb3ZpZGVycyIsInZpZXctcmVhbG0iLCJtYW5hZ2UtaWRlbnRpdHktcHJvdmlkZXJzIiwiaW1wZXJzb25hdGlvbiIsImNyZWF0ZS1jbGllbnQiLCJtYW5hZ2UtdXNlcnMiLCJ2aWV3LWF1dGhvcml6YXRpb24iLCJtYW5hZ2UtZXZlbnRzIiwibWFuYWdlLXJlYWxtIiwidmlldy1ldmVudHMiLCJ2aWV3LXVzZXJzIiwidmlldy1jbGllbnRzIiwibWFuYWdlLWF1dGhvcml6YXRpb24iLCJtYW5hZ2UtY2xpZW50cyJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsInZpZXctcHJvZmlsZSJdfX0sImNsaWVudEhvc3QiOiIxMjcuMC4wLjEiLCJjbGllbnRJZCI6ImFkYXB0ZXIiLCJuYW1lIjoiIiwicHJlZmVycmVkX3VzZXJuYW1lIjoic2VydmljZS1hY2NvdW50LWFkYXB0ZXIiLCJjbGllbnRBZGRyZXNzIjoiMTI3LjAuMC4xIiwiZW1haWwiOiJzZXJ2aWNlLWFjY291bnQtYWRhcHRlckBwbGFjZWhvbGRlci5vcmcifQ.FPwPxbx_eQ2zDUXjUDKY9KJxKMN9aowVCJlXht9za-lr48CS6g8T3NnvVk112PkpuAAVPvN2djIWjrqfsppNnqPnqsZ41ZqcBJXl7Af7pnfvkIvWxqjNx3rKkCRg9uPs4Bo-bjJzQt4ZFjONihhpGCbjMcUtgMXodJkOW9euSvgSEOHCzyXDji-y2kqUV7bUkTEdOppVgT3TN5ZP955lvvDTmskZl3xlqOUitReoBiRzOBIvD1bMa59dsNI5csHT3btr3h2SGxr2olRU6rzGLTllpwkmiuDAi1VHMR66lVF-LlZkFeA58Qj7wiLBBW5peGbNRX1Dz-uGIzht0tVexA'

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

    url = URI("http://localhost:8081/auth/realms/SONATA/protocol/openid-connect/token")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Post.new(url.to_s)
    request["authorization"] = 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJqZjQ3WXlHSzQ3VUprLXJ1cUk5RV9IaDhsNS1heHFrMzkxX0NpUUhmTm9nIn0.eyJqdGkiOiI3ZDBiYzEwNy1iYzViLTQ4YmItYjU3Ny0wYjdjOGIyZGJjOTkiLCJleHAiOjE0NzgyNjc4NDAsIm5iZiI6MCwiaWF0IjoxNDc4MjY2OTQwLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODEvYXV0aC9yZWFsbXMvbWFzdGVyIiwiYXVkIjoiYWRhcHRlciIsInN1YiI6IjY3Y2RmMjEzLTM0OWItNDUzOS1iZGIyLTQzMzUxYmYzZjU2ZSIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkYXB0ZXIiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiJiNzU3MjhkZi1hZTBiLTQxZTAtYjY1Yy00N2QxYmNhZGRhMzAiLCJhY3IiOiIxIiwiY2xpZW50X3Nlc3Npb24iOiI0ZTBmNTYxMy0xNGY5LTRmYWEtOWEwMS02YTgyOWYwMGQ5ODQiLCJhbGxvd2VkLW9yaWdpbnMiOltdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiY3JlYXRlLXJlYWxtIiwiYWRtaW4iLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFkYXB0ZXIiOnsicm9sZXMiOlsidW1hX3Byb3RlY3Rpb24iXX0sIm1hc3Rlci1yZWFsbSI6eyJyb2xlcyI6WyJ2aWV3LWlkZW50aXR5LXByb3ZpZGVycyIsInZpZXctcmVhbG0iLCJtYW5hZ2UtaWRlbnRpdHktcHJvdmlkZXJzIiwiaW1wZXJzb25hdGlvbiIsImNyZWF0ZS1jbGllbnQiLCJtYW5hZ2UtdXNlcnMiLCJ2aWV3LWF1dGhvcml6YXRpb24iLCJtYW5hZ2UtZXZlbnRzIiwibWFuYWdlLXJlYWxtIiwidmlldy1ldmVudHMiLCJ2aWV3LXVzZXJzIiwidmlldy1jbGllbnRzIiwibWFuYWdlLWF1dGhvcml6YXRpb24iLCJtYW5hZ2UtY2xpZW50cyJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsInZpZXctcHJvZmlsZSJdfX0sImNsaWVudEhvc3QiOiIxMjcuMC4wLjEiLCJjbGllbnRJZCI6ImFkYXB0ZXIiLCJuYW1lIjoiIiwicHJlZmVycmVkX3VzZXJuYW1lIjoic2VydmljZS1hY2NvdW50LWFkYXB0ZXIiLCJjbGllbnRBZGRyZXNzIjoiMTI3LjAuMC4xIiwiZW1haWwiOiJzZXJ2aWNlLWFjY291bnQtYWRhcHRlckBwbGFjZWhvbGRlci5vcmcifQ.FPwPxbx_eQ2zDUXjUDKY9KJxKMN9aowVCJlXht9za-lr48CS6g8T3NnvVk112PkpuAAVPvN2djIWjrqfsppNnqPnqsZ41ZqcBJXl7Af7pnfvkIvWxqjNx3rKkCRg9uPs4Bo-bjJzQt4ZFjONihhpGCbjMcUtgMXodJkOW9euSvgSEOHCzyXDji-y2kqUV7bUkTEdOppVgT3TN5ZP955lvvDTmskZl3xlqOUitReoBiRzOBIvD1bMa59dsNI5csHT3btr3h2SGxr2olRU6rzGLTllpwkmiuDAi1VHMR66lVF-LlZkFeA58Qj7wiLBBW5peGbNRX1Dz-uGIzht0tVexA'

    request["content-type"] = 'application/json'
    request.body = body.to_json

    response = http.request(request)
    puts response.read_body

  end

  def logout

  end
end