require 'json'
require 'jwt'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
require 'yaml'
require_relative 'helpers/init'
require_relative 'routes/init'

# Set environment
ENV['RACK_ENV'] ||= 'development'

require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

configure do
  # Configuration for logging
  enable :logging
  Dir.mkdir("#{settings.root}/log") unless File.exist?("#{settings.root}/log")
  log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  log_file.sync = true
  use Rack::CommonLogger, log_file

  # turn keycloak realm pub key into an actual openssl compat pub key.
  #keycloak_config = JSON.parse(File.read('keycloak.json'))
  #@s = "-----BEGIN PUBLIC KEY-----\n"
  #@s += keycloak_config['realm-public-key'].scan(/.{1,64}/).join("\n")
  #@s += "\n-----END PUBLIC KEY-----\n"
  #@key = OpenSSL::PKey::RSA.new @s
  #set :keycloak_pub_key, @key
  #set :keycloak_client_id, keycloak_config['resource']
  #set :keycloak_url, keycloak_config['auth-server-url'] + '/' + keycloak_config['realm'] + '/'

  # configure clever client. the clever-ruby gem uses a global to handle interactions.
  # Clever.configure do |config|
  #   config.token = 'DEMO_TOKEN'
  # end
  # Print token settings
  # puts "settings.keycloak_pub_key: ", settings.keycloak_pub_key

  # set up the rest of sinatra config stuffz
  set :server, :puma
  set :environment, :production
end


before do
  logger.level = Logger::DEBUG
end

# Configurations
class Adapter < Sinatra::Application
  register Sinatra::ConfigFile
  # Load configurations
  config_file 'config/config.yml'
end

configure do
  # turn keycloak realm pub key into an actual openssl compat pub key.
  keycloak_config = JSON.parse(File.read('config/keycloak.json'))
  @s = "-----BEGIN PUBLIC KEY-----\n"
  @s += keycloak_config['realm-public-key'].scan(/.{1,64}/).join("\n")
  @s += "\n-----END PUBLIC KEY-----\n"
  @key = OpenSSL::PKey::RSA.new @s
  set :keycloak_pub_key, @key
  set :keycloak_client_id, keycloak_config['resource']
  set :keycloak_url, keycloak_config['auth-server-url'] + '/' + keycloak_config['realm'] + '/'

  # Print token settings
  puts "settings.keycloak_pub_key: ", settings.keycloak_pub_key

  set :server, :puma
  set :environment, :production
end

class SecuredAPI < Sinatra::Application
  use JwtAuth

  def initialize
    super

    # Read users-rights from a datasource
    @accounts = {
        user1: [{'Service' => 'FW'}],
        user2: [{'Service' => 'FW'}, {'Service' => 'LB'}],
        user3: [{'Service' => 'LB'}, ]
    }
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

class PublicAPI < Sinatra::Application
  def initialize
    super

    # User credentials will be stored on a database
    @logins = {
        user1: '1234',
        user2: '1234',
        user3: '1234'
    }
  end

  def token username
    JWT.encode payload(username), ENV['JWT_SECRET'], 'HS256'
  end

  def payload username
    # if user else devuser?
    {
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: ['add_services', 'remove_services', 'view_services'],
      user: {
          username: username
      }
    }
  end
end
