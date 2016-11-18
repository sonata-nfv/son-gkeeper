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


class SecuredAPI < Sinatra::Application
  use JwtAuth

  def initialize
    super

    # Read users-rights form a datasource
    @accounts = {
        user1: [{'Service' => 'FW'}],
        user2: [{'Service' => 'FW'}, {'Service' => 'LB'}],
        user3: [{'Service' => 'LB'}, ]
    }
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
