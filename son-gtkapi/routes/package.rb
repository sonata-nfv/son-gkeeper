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
require 'sinatra/namespace'
class GtkApi < Sinatra::Base

  register Sinatra::Namespace
  
  namespace '/api/v2/packages' do
    # POST of packages
    post '/?' do
      log_message = 'GtkApi::POST /api/v2/packages/?'
      logger.info(log_message) {"entered with params=#{params}"}
    
      unless params[:package].nil?
        if params[:package][:tempfile]
          # TODO: we're fixing the user here, but it should come from the request
          resp = PackageManagerService.create(params.merge({user: {name: 'Unknown', password: 'None'}}))
          logger.debug(log_message) {"resp=#{resp.inspect}"}
          case resp[:status]
          when 201
            logger.info(log_message) {"leaving with package: #{resp[:data][:uuid]}"}
            headers 'Location'=> PackageManagerService.class_variable_get(:@@url)+"/packages/#{resp[:data][:uuid]}", 'Content-Type'=> 'application/json'
            halt 201, resp[:data].to_json
          when 409
            logger.error(log_message) {"leaving with duplicated package: #{resp[:data]}"}
            headers 'Content-Type'=> 'application/json'
            halt 409, resp[:data].to_json
          when 400
            message = "Error creating package #{params}"
            logger.error(log_message) {message}
            headers 'Content-Type'=> 'application/json'
            json_error 400, message
          else
            message = "Unknown status: #{resp[:status]} for package #{params}"
            logger.error(log_message) {message}
            json_error resp[:status], message
          end
        else
          json_error 400, 'Temp file name not provided'
        end
      end
      json_error 400, "No package file specified: #{params}"
    end

  # GET a specific package
    get '/:uuid/?' do
      log_message = 'GtkApi::GET /api/v2/packages/:uuid/?'
      logger.debug(log_message) {'entered'}
      unless params[:uuid].nil?
        logger.debug(log_message) {"params[:uuid]=#{params[:uuid]}"}
        json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
        package = PackageManagerService.find_by_uuid(params[:uuid])
        if package
          logger.debug(log_message) {"leaving with package #{package}"}
          halt 200, package
        else
          logger.debug(log_message) {"leaving with \"No package with UUID=#{params[:uuid]} was found\""}
          json_error 404, "No package with UUID=#{params[:uuid]} was found"
        end
      end
      logger.debug(log_message) {"leaving with \"No package UUID specified\""}
      json_error 400, 'No package UUID specified'      
    end
  
    # GET potentially many packages
    get '/?' do
      log_message = 'GtkApi::GET /api/v2/packages/?'
      logger.debug(log_message) {'entered with '+query_string}
    
      @offset ||= params[:offset] ||= DEFAULT_OFFSET
      @limit ||= params[:limit] ||= DEFAULT_LIMIT
    
      packages = PackageManagerService.find(params)
      if packages
        logger.debug(log_message) { "leaving with #{packages}"}
        # TODO: total must be returned from the PackageManagement service
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: packages.size)
        [200, {'Link' => links}, packages]
      else
        error_message = 'No packages found' + (query_string.empty? ? '' : ' with parameters '+query_string)
        json_error 404, error_message, log_message
      end
    end
  
    # PUT 
    put '/:uuid/?' do
      # TODO
      log_message = 'GtkApi::PUT /api/v2/packages/:uuid/?'
      unless params[:uuid].nil?
        logger.info(log_message) { "entered with package id #{params[:uuid]}"}
        logger.info(log_message) { "leaving with \"Not implemented yet\""}
      end
      json_error 501, "Not implemented yet", log_message
    end
  
    # DELETE
    delete '/:uuid/?' do
      log_message = 'GtkApi::DELETE /api/v2/packages/:uuid/?'
      unless params[:uuid].nil?
        logger.info(log_message) { "entered with package id #{params[:uuid]}"}
        packages = PackageManagerService.delete(params[:uuid])
        if packages
          logger.debug(log_message) { "deleted package with uuid=#{params[:uuid]}"}
          [200, {}, '']
        else
          json_error 404, 'No package found with uuid='+params[:uuid], log_message
        end
      else
        json_error 404, 'Package uuid needed', log_message
      end
    end
  end
  
  namespace '/api/v2/admin/packages' do
    get '/logs/?' do
      log_message = 'GtkApi::GET /api/v2/admin/packages/logs'
      logger.debug(log_message) {'entered'}
      url = PackageManagerService.class_variable_get(:@@url)+'/admin/logs'
      log = PackageManagerService.get_log(url: url, log_message:log_message)
      logger.debug(log_message) {'leaving with log='+log}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      halt 200, log #.to_s
    end
  end
end

#get '/downloads/:filename' do
#  puts "Params: " + params.inspect
#  puts "Headers: " + headers.inspect
#  url = 'http://localhost:5678/downloads/'
#  puts "Getting file "+params[:filename]+" from "+url

#  response = RestClient.get(url+params[:filename])
#  puts "Saving file on '/files/p1'..."
#  File.open(File.join('files/p1', params[:filename]), 'wb') do |f|
#    f.write response #.body.read
#  end
#  send_file 'files/p1/'+params[:filename]
#end


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
