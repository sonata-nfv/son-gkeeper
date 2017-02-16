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

# Set environment
ENV['RACK_ENV'] ||= 'development'

require 'sinatra'
require 'sinatra/base'
require 'sinatra/config_file'
#require 'sinatra/logger'
require 'json'
require 'yaml'
require 'jwt'

require_relative 'helpers/init'
require_relative 'routes/init'
# require_relative 'models/init'

# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

configure do
  # Configuration for logging
  enable :logging
  Dir.mkdir("#{settings.root}/log") unless File.exist?("#{settings.root}/log")
  log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  log_file.sync = true
  use Rack::CommonLogger, log_file

  class Keycloak < Sinatra::Application
    register Sinatra::ConfigFile
    # Load configurations
    config_file 'config/keycloak.yml'

    self.get_oidc_endpoints
    self.get_adapter_install_json
    @@access_token = self.get_adapter_token
  end

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

  # set up the rest of sinatra config stuff
  set :server, :puma
  set :environment, :production
end

before do
  logger.level = Logger::DEBUG
end

# Configurations
# Authorization and operations class, it build sa security context based on an existing token and uses that
# to access protected resources (operation layer)
class Adapter < Sinatra::Application
  register Sinatra::ConfigFile
  # Load configurations
  config_file 'config/config.yml'
end

# DEPRECATED API - only to apply testings
=begin
class SecuredAPI < Sinatra::Application
  use JwtAuth

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