## SONATA - Gatekeeper
##
## Copyright 2015-2017 Portugal Telecom Inovacao/Altice Labs
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
# encoding: utf-8
ENV['RACK_ENV'] ||= 'production'

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/config_file'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra/logger'

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative 'routes/init'
require_relative 'helpers/init'
require_relative 'models/init'

# Main class supporting the Gatekeeper's Service Management micro-service
class GtkSrv < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::CrossOrigin
  register Sinatra::Reloader
  register Sinatra::ActiveRecordExtension
  register Sinatra::Logger
  set :logger_level, :debug # or :fatal, :error, :warn, :info
  
  helpers GtkSrvHelper
  
  set :root, File.dirname(__FILE__)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :bind, '0.0.0.0'
  set :time_at_startup, Time.now.utc
  set :environments, %w(development test integration qualification demonstration)
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join(root, 'config', 'services.yml')
  configure do
    set :catalogues, {'url': 'http://localhost:5200/catalogues'}
    #set :database, {adapter: 'postgresql', host: 'localhost', database: 'sonata', encoding: 'utf8', pool: 5}
  end
  
  configure :integration do
    set :catalogues, {'url': 'http://sp.int.sonata-nfv.eu:4002/catalogues'}
    set :mqserver, {'url': 'amqp://guest:guest@localhost:5673'}
    #set :db, {'url': 'postgres://postgres:sonatatest@jenkins.sonata-nfv.eu:5432/sonata'} # TODO: read this from ENV
    set :database_file, File.join('config', 'database.yml')
  end
  
	use Rack::Session::Cookie, key: 'rack.session', domain: 'foo.com', path: '/', expire_after: 2592000, secret: '$0nata'
	enable :logging
  FileUtils.mkdir(File.join(settings.root, 'log')) unless File.exists? File.join(settings.root, 'log')
  logfile = File.open('log/'+ENV['RACK_ENV']+'.log', 'a+')
  $stdout.reopen(logfile, "w")
  $stderr.reopen(logfile, "w")
  enable :cross_origin
end
