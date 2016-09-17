## SONATA - Gatekeeper
##
## Copyright (c) 2015 SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
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
## Neither the name of the SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote 
## products derived from this software without specific prior written 
## permission.
## 
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through 
## the Horizon 2020 and 5G-PPP programmes. The authors would like to 
## acknowledge the contributions of their colleagues of the SONATA 
## partner consortium (www.sonata-nfv.eu).
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
  
  helpers GtkSrvHelper
  
  MODULE='GtkSrv'
  
  set :root, File.dirname(__FILE__)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :bind, '0.0.0.0'
  set :time_at_startup, Time.now.utc
  set :environments, %w(development test integration qualification demonstration)
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join( [root, 'config', 'services.yml.erb'] )
    
  use Rack::Session::Cookie, :key => 'rack.session', :domain => 'foo.com', :path => '/', :expire_after => 2592000, :secret => '$0nata'
  
  # Logging
	enable :logging
  set :logger_level, :debug # or :fatal, :error, :warn, :info
  FileUtils.mkdir(File.join(settings.root, 'log')) unless File.exists? File.join(settings.root, 'log')
  logfile = File.open(File.join('log', ENV['RACK_ENV'])+'.log', 'a+')
  logfile.sync = true
  logger = Logger.new(logfile)
    
  enable :cross_origin

  if settings.catalogues
    set :services_catalogue, Catalogue.new(settings.catalogues+'/network-services', logger)
    set :functions_catalogue, Catalogue.new(settings.catalogues+'/vnfs', logger)
  else
    logger.error(MODULE) {'>>>Catalogue url not defined, application being terminated!!'}
    Process.kill('TERM', Process.pid)
  end
  if settings.mqserver_url
    set :mqserver, MQServer.new(settings.mqserver_url, logger)
    set :update_server, UpdateServer.new(settings.mqserver_url, logger)
  else
    logger.error(MODULE) {'>>>MQServer url not defined, application being terminated!!'}
    Process.kill('TERM', Process.pid)
  end
  logger.info(MODULE) {"started at #{settings.time_at_startup}"}
  logger.info(MODULE) {"Services Catalogue: #{settings.services_catalogue.url}"}
  logger.info(MODULE) {"Functions Catalogue: #{settings.functions_catalogue.url}"}
  logger.info(MODULE) {"MQServer: #{settings.mqserver.url}"}
  logger.info(MODULE) {"UpdateServer: #{settings.update_server.url}"}
end
