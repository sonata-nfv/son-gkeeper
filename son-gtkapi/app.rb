## SONATA - Gatekeeper
##
## Copyright 2015-2017 Portugal Telecom Inovação/Altice Labs
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
require 'sinatra'
require 'sinatra/config_file'
require 'json'
require 'yaml'
require 'rack/parser'
require 'rest-client'
require 'sinatra/cross_origin'
require 'fileutils'
require 'zip'
require 'pp'

set :root, File.dirname(__FILE__)
set :bind, '0.0.0.0'
set :public_folder, File.join(File.dirname(__FILE__), 'public')
set :files, File.join(settings.public_folder, 'files')

use Rack::Session::Cookie, :key => 'rack.session', :domain => 'foo.com', :path => '/', :expire_after => 2592000, :secret => '$0nata'

enable :logging
enable :cross_origin

config_file 'config/services.yml'

# https://github.com/achiu/rack-parser
use Rack::Parser, :content_types => { 'application/json' => Proc.new { |body| ::MultiJson.decode body } }

# TODO: time to change to a different Sinatra App style
class Package
  
  def self.save(path, params)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    
    package_file_path = File.join(path, params[:package][:filename])
    File.open(package_file_path, 'wb') do |file|
      file.write params[:package][:tempfile].read
    end
    package_file_path
  end
  
  def self.onboard(url, file_path, file_name)
    headers = { accept: 'application/json', content_type: 'application/octet-stream'}
    package = { filename: file_name, type: 'application/octet-stream', name: 'package', tempfile: File.new(file_path, 'rb').read,
      head: "Content-Disposition: form-data; name=\"package\"; filename=\"#{file_name}\"\r\nContent-Type: application/octet-stream\r\n"
    }
    begin
      RestClient.post( url, {package: package}, headers) 
    rescue => e
      e.inspect
      [500, '', e]
    end
  end
end

helpers do
  def content
    #@content ||= Package.decode(package_file_path) || halt 404
  end  
  
  def json_error(code, message)
    msg = {'error' => message}
    logger.error msg.to_s
    halt code, {content_type: 'application/json'}, msg.to_json
  end
end

get '/' do
  headers "Content-Type" => "text/plain; charset=utf8"
  api = open('./config/api.yml')
  halt 200, {'Location' => '/'}, api.read.to_s
end

get '/api-doc' do
  erb :api_doc
end

post '/packages/?' do
  unless params[:package].nil?    
    package_file_path = Package.save( settings.files, params)
    if package_file_path
      logger.info "package_file_path: #{package_file_path}"
      package = Package.onboard( settings.pkgmgmt['url'], package_file_path, params[:package][:filename])
      if package
        logger.info "package: #{package}"
        if package['uuid']
          headers = {'location'=> "#{settings.pkgmgmt['url']}/#{package['uuid']}", 'content-type'=> 'application/json'}
          halt 201, headers, package.to_json
        else
          json_error 400, 'No UUID given to package'
        end
      else
        json_error 400, 'Package not created'
      end
    else
      json_error 400, 'Package with invalid content'
    end
  end
  json_error 400, 'No package file specified'
end

#get '/download/*.*' do
#  file = "#{params[:splat].first}.#{params[:splat].last}"
#  path = "<path to files directory>/#{file}"
  #
#  if File.exists? path
#  send_file(
#    path, :disposition => 'attachment', : filename => file
#  )
#  else
#      halt 404, "File not found"
#  end
#end
