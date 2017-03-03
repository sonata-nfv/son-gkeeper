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
# Set environment
ENV['RACK_ENV'] ||= 'production'

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'zip'
require 'sinatra/logger'
require 'sinatra/namespace'
#require 'active_support/all'

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

['helpers', 'routes', 'models'].each do |dir|
  Dir[File.join(File.dirname(__FILE__), dir, '**', '*.rb')].each do |file|
    require file
  end
end

# Concentrates all the REST API of the Gatekeeper
class GtkApi < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::CrossOrigin
  register Sinatra::Reloader
  register Sinatra::Logger
  register Sinatra::Namespace
  
  helpers GtkApiHelper

  set :root, File.dirname(__FILE__)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :bind, '0.0.0.0'
  set :files, File.join(settings.public_folder, 'files')
  set :began_at, Time.now.utc
  set :environments, %w(development test integration qualification demonstration)
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join(root, 'config', 'services.yml')
  
  use Rack::Session::Cookie, key: 'rack.session', domain: 'foo.com', path: '/', expire_after: 2592000, secret: '$0nata'
  
  # Logging  
  MODULE = 'GtkApi'

	enable :logging
  FileUtils.mkdir(File.join(settings.root, 'log')) unless File.exists? File.join(settings.root, 'log')
  logfile = File.open(File.join('log', ENV['RACK_ENV'])+'.log', 'a+')
  logfile.sync = true
  set :logger, Logger.new(logfile)
  raise 'Can not proceed without a logger file' if settings.logger.nil?
  set :logger_level, (ENV['LOGGER_LEVEL'] || settings.level ||= 'debug').to_sym # can be debug, fatal, error, warn, or info
  settings.logger.info(MODULE) {"Started at #{settings.began_at}"}
  settings.logger.info(MODULE) {"Logger level at :#{settings.logger_level} level"}
  
  enable :cross_origin
  #enable :method_override

  # TODO: make this relationship loosely coupled
  # TODO: logger could be a global variable
  PackageManagerService.config(url: ENV['PACKAGE_MANAGEMENT_URL'] || settings.pkgmgmt)
  ServiceManagerService.config(url: ENV['SERVICE_MANAGEMENT_URL'] || settings.srvmgmt)
  FunctionManagerService.config(url: ENV['FUNCTION_MANAGEMENT_URL'] || settings.fnctmgmt)
  RecordManagerService.config(url: ENV['RECORD_MANAGEMENT_URL'] || settings.recmgmt)
  LicenceManagerService.config(url: ENV['LICENCE_MANAGEMENT_URL'] || settings.licmgmt)
  VimManagerService.config(url: ENV['VIM_MANAGEMENT_URL'] || settings.vimmgmt)
  KpiManagerService.config(url: ENV['KPI_MANAGEMENT_URL'] || settings.kpimgmt)
  User.config(url: ENV['USER_MANAGEMENT_URL'] || settings.usrmgmt)
  
  Zip.setup do |c|
    c.unicode_names = true
    c.on_exists_proc = true
    c.continue_on_exists_proc = true
  end
  
  def query_string
    log_message = 'GtkApi::query_string'
    settings.logger.debug(log_message) {"query_string=#{request.env['QUERY_STRING']}"}
    request.env['QUERY_STRING'].empty? ? '' : '?' + request.env['QUERY_STRING'].to_s
  end

  def request_url
    log_message = 'GtkApi::request_url'
    settings.logger.debug(log_message) {"Schema=#{request.env['rack.url_scheme']}, host=#{request.env['HTTP_HOST']}, path=#{request.env['REQUEST_PATH']}"}
    "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}#{request.env['REQUEST_PATH']}"
  end
end
