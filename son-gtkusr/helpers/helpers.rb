require 'json'
require 'sinatra'
require 'net/http'
# require 'openssl'
# require 'yaml'
# require 'open-uri'

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

class JwtAuth

  def initialize app
    @app = app
  end

  def call env
    begin
      options = {algorithm: 'HS256', iss: ENV['JWT_ISSUER']}
      p options
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      p bearer
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      env[:scopes] = payload['scopes']
      env[:user] = payload['user']

      @app.call env
    rescue JWT::DecodeError
      [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']] # Even if it expires, shows this error
    rescue JWT::ExpiredSignature
      [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    end
  end
end
