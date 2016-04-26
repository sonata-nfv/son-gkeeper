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
require 'json' 
require 'pp'
require 'addressable/uri'

class Gtkpkg < Sinatra::Base

  # Receive the Java package
  #post '/uploads' do
  #  puts "Params: " + params.inspect
  #  puts "Headers: " + headers.inspect
  #  if params[:file]
  #    filename = params[:file][:filename]
  #    file = params[:file][:tempfile]

  #    File.open(File.join('files/p2', filename), 'wb') do |f|
  #      f.write file.read
  #    end
  #    puts 'Upload successful'
  #  else
  #    puts 'You have to choose a file'
  #  end
  #end

  post '/packages/?' do
    logger.info "GtkPkg: entered POST /packages with params = #{params}"
    
    #package = Package.new(io: File.open(params[:package][:tempfile], 'rb').read).unbuild()
    package = Package.new(io: params[:package][:tempfile][:tempfile]).unbuild()
    logger.info "GtkPkg: POST /packages package #{package.to_json}"
    if package && package['uuid']
      logger.info "GtkPkg: leaving POST /packages with package #{package.to_json}"
      halt 201, {'Location' => "/packages/#{package['uuid']}"}, package.to_json
    else
      logger.info "GtkPkg: leaving POST /packages with 'No package created'"
      json_error 400, 'No package created'
    end
  end
  
  get '/packages/:uuid' do
    unless params[:uuid].nil?
      logger.info "GtkPkg: entered GET \"/packages/#{params[:uuid]}\""
      package = Package.find_by_uuid( params[:uuid])
      if package && package.is_a?(Hash) && package['uuid']
        logger.info "GtkPkg: in GET /packages/#{params[:uuid]}, found package #{package}"
        response = Package.new(descriptor: package).build()    
        if response
          logger.info "GtkPkg: leaving GET /packages/#{params[:uuid]} with package found and sent in file .../#{package['package_name']}.son"
          halt 200, { 'filepath'=>File.join('public', 'packages', params[:uuid], package['package_name']+'.son')}.to_json
        else
          logger.error "GtkPkg: leaving GET /packages/#{params[:uuid]}, with 'Could not create package file'."
          json_error 400, "Could not create package file"
        end
      else
        logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
  
  get '/packages/:uuid/package?' do
    unless params[:uuid].nil?
      logger.debug "GtkPkg: entered GET /packages/#{params[:uuid]}/package"
      file_dir = File.join('public','packages',params[:uuid])
      entries = Dir.entries(file_dir) - %w(. ..)
      logger.debug "GtkPkg: entries are #{entries}"
      send_file File.join('public','packages',params[:uuid], entries[0]) if entries.size
    end
    logger.info "GtkPkg: leaving GET /packages/#{params[:uuid]}/package with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end

  get '/packages' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkPkg: entered GET \"/packages/#{uri.query}\""
    
    packages = Package.find(params)
    logger.debug "Gtkpkg: GET /packages: #{packages}"
    if packages && packages.is_a?(Array)
      if packages.size == 1
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, found package #{packages[0]}"
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, generating package"
        response = Package.new(descriptor: packages[0]).build()
        if response
          logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"Package #{packages[0]['uuid']} found and sent in file \"#{packages[0]['package_name']}\"\""
          send_file response #File.join(response, packages[0]['package_name'])
        else
          logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\", with \"Could not create package file\"."
          json_error 400, "Could not create package file"
        end
      else
        logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"Found #{packages.size} packages\""
        halt 200, packages.to_json
      end
    else
      logger.info "GtkPkg: leaving GET /packages/#{uri.query} with \"No package with params #{uri.query} was found\""
      json_error 404, "No package with params #{uri.query} was found"
    end
  end
  
  get '/admin/logs' do
    logger.debug "GtkPkg: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end
end
