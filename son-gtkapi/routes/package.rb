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
          package = PackageManagerService.create(params)
          logger.debug(log_message) {"package=#{package.inspect}"}
          if package
            if package.is_a?(Hash) && (package[:uuid] || package['uuid'])
              logger.info(log_message) {"leaving with package: #{package}"}
              headers = {'location'=> PackageManagerService.url+"/packages/#{package[:uuid]}", 'Content-Type'=> 'application/json'}
              halt 201, headers, package.to_json
            elsif package.is_a?(Hash) && package.key?(:package)
              #(package[:vendor] || package['vendor']) && (package[:version] || package['version']) && (package[:name] || package['name'])
              logger.info(log_message) {"leaving with duplicated package: #{package}"}
              headers = {'Content-Type'=> 'application/json'}
              halt 409, headers, package[:package].to_json
            else
              json_error 400, 'No UUID given to package'
            end
          else
            json_error 400, 'Package not created'
          end
        else
          json_error 400, 'Temp file name not provided'
        end
      end
      json_error 400, 'No package file specified'
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
        error_message = 'No package found with parameters '+query_string
        logger.debug(log_message) {'leaving with "'+error_message+'"'}
        json_error 404, error_message
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
      json_error 501, "Not implemented yet"
    end
  
    # DELETE
    delete '/:uuid/?' do
      # TODO
      log_message = 'GtkApi::DELETE /api/v2/packages/:uuid/?'
      unless params[:uuid].nil?
        logger.info(log_message) { "entered with package id #{params[:uuid]}"}
        logger.info(log_message) { "leaving with \"Not implemented yet\""}
      end
      json_error 501, "Not implemented yet"
    end
  end
  
  namespace '/api/v2/admin/packages' do
    get '/logs/?' do
      log_message = 'GtkApi::GET /api/v2/admin/packages/logs'
      logger.debug(log_message) {'entered'}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      log = PackageManagerService.get_log(url:PackageManagerService.url+'/admin/logs', log_message:log_message, logger: logger)
      logger.debug(log_message) {'leaving with log='+log}
      halt 200, log #.to_s
    end
  end
  
  private
    
  def query_string
    request.env['QUERY_STRING'].empty? ? '' : '?' + request.env['QUERY_STRING'].to_s
  end

  def request_url
    request.env['rack.url_scheme']+'://'+request.env['HTTP_HOST']+request.env['REQUEST_PATH']
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
