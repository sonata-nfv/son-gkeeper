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
require 'sinatra/logger'
require 'zip'

# Require the bundler gem and then call Bundler.require to load in all gems listed in Gemfile.
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative 'routes/init'
require_relative 'helpers/init'
require_relative 'models/init'

class Gtkpkg < Sinatra::Base
  register Sinatra::ConfigFile
  register Sinatra::CrossOrigin
  register Sinatra::Logger
  set :logger_level, :debug # or :fatal, :error, :warn, :info
  
  helpers GtkPkgHelpers
  
  config_file 'config/services.yml'

# https://github.com/achiu/rack-parser
#use Rack::Parser, :content_types => { 'application/json' => Proc.new { |body| ::MultiJson.decode body } }

  set :root, File.dirname(__FILE__)
  set :public_folder, File.join(File.dirname(__FILE__), 'public')
  set :bind, '0.0.0.0'
  set :time_at_startup, Time.now.utc
  set :environments, %w{development test integration qualification demonstration}
  set :environment, ENV['RACK_ENV'] || :development
  config_file File.join( [root, 'config', 'services.yml'] )
  #puts Gtkpkg.settings.catalogues['url']
    
  use Rack::Session::Cookie, :key => 'rack.session', :domain => 'foo.com', :path => '/', :expire_after => 2592000, :secret => '$0nata'
  enable :logging
  FileUtils.mkdir(File.join(settings.root, 'log')) unless File.exists? File.join(settings.root, 'log')
  logfile = File.open('log/'+ENV['RACK_ENV']+'.log', 'a+')
  $stdout.reopen(logfile, "w")
  $stderr.reopen(logfile, "w")
  $stdout.sync = true
  $stderr.sync = true
  enable :cross_origin

	Zip.setup do |c|
    c.unicode_names = true
	  c.on_exists_proc = true
	  c.continue_on_exists_proc = true
  end
  #mime_type :son, 'application/octet-stream'
  
end