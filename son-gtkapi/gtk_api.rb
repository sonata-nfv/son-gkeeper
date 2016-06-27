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
# Set environment
ENV['RACK_ENV'] ||= 'production'

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'zip'
require 'sinatra/logger'

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative 'routes/init'
require_relative 'helpers/init'
require_relative 'models/init'

# Concentrates all the REST API of the Gatekeeper
class GtkApi < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::CrossOrigin
  register Sinatra::Reloader
  register Sinatra::Logger
  set :logger_level, :debug # or :fatal, :error, :warn, :info
  
  helpers GtkApiHelper

  set :root, File.dirname(__FILE__)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :bind, '0.0.0.0'
  set :files, File.join(settings.public_folder, 'files')
  set :time_at_startup, Time.now.utc
  set :environments, %w(development test integration qualification demonstration)
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join(root, 'config', 'services.yml.erb')
  
  use Rack::Session::Cookie, key: 'rack.session', domain: 'foo.com', path: '/', expire_after: 2592000, secret: '$0nata'
  
  # Logging
	enable :logging
  FileUtils.mkdir(File.join(settings.root, 'log')) unless File.exists? File.join(settings.root, 'log')
  logfile = File.open(File.join('log', ENV['RACK_ENV'])+'.log', 'a+')
  logfile.sync = true
  logger = Logger.new(logfile)
  
  enable :cross_origin

  set :package_management, PackageManagerService.new(settings.pkgmgmt, logger)
  set :service_management, ServiceManagerService.new(settings.srvmgmt, logger)
  set :function_management,FunctionManagerService.new(settings.fnctmgmt, logger)
  set :vim_management,VimManagerService.new(settings.vimmgmt, logger)
  
  Zip.setup do |c|
    c.unicode_names = true
    c.on_exists_proc = true
    c.continue_on_exists_proc = true
  end
  logger.info "GtkApi started at #{settings.time_at_startup}"
end
