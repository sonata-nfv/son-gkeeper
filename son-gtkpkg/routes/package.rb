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
require 'json' 
require 'pp'
require 'addressable/uri'

class GtkPkg < Sinatra::Base

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
    logger.info('GtkPkg.post /packages') {"params = #{params}"}
    
    package = Package.new(catalogue: settings.packages_catalogue, logger: logger, params: {io: params[:package][:tempfile][:tempfile]})
    if package 
      logger.debug('GtkPkg.post /packages') {"package=#{package.inspect}"}
      descriptor = package.from_file()
      logger.info('GtkPkg.post /packages') {"descriptor is #{descriptor}"}
      if descriptor && descriptor['uuid']
        logger.info('GtkPkg.post /packages') {"leaving with package #{descriptor.to_json}"}
        halt 201, {'Location' => "/packages/#{descriptor['uuid']}"}, descriptor.to_json
      else
        logger.error('GtkPkg.post /packages') {"leaving with 'Error generating package descriptor'"}
        json_error 400, 'Error generating package descriptor'
      end
    else
      logger.error('GtkPkg.post /packages') {"leaving with 'No package created'"}
      json_error 400, 'No package created'
    end
  end
  
  get '/packages/:uuid' do
    unless params[:uuid].nil?
      logger.info('GtkPkg.get') { "GtkPkg: entered GET \"/packages/#{params[:uuid]}\""}
      #package = Package.find_by_uuid( params[:uuid], logger)
      package = settings.packages_catalogue.find_by_uuid( params[:uuid])
      if package && package.is_a?(Hash) && package['uuid']
        logger.info "GtkPkg: in GET /packages/#{params[:uuid]}, found package #{package}"
        response = Package.new(catalogue: settings.packages_catalogue, logger: logger, params: {descriptor: package}).to_file()    
        if response
          logger.info "GtkPkg: leaving GET /packages/#{params[:uuid]} with package found and sent in file .../#{package['name']}.son"
          halt 200, { 'filepath'=>File.join('public', 'packages', params[:uuid], package['name']+'.son')}.to_json
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

  get '/packages/?' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkPkg: entered GET \"/packages/#{uri.query}\""
    
    #packages = Package.find(params, logger)
    packages = settings.packages_catalogue.find(params)
    logger.debug "GtkPkg: GET /packages: #{packages}"
    if packages && packages.is_a?(Array)
      if packages.size == 1
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, found package #{packages[0]}"
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, generating package"
        response = Package.new(catalogue: settings.packages_catalogue, logger: logger, params: {descriptor: packages[0]}).to_file()
        if response
          logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"Package #{packages[0]['uuid']} found and sent in file \"#{packages[0]['name']}\"\""
          send_file response #File.join(response, packages[0]['name'])
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
  
  get '/admin/logs/?' do
    logger.debug "GtkPkg: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end
end
