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
require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/streaming'
require 'base64'

class GtkApi < Sinatra::Base

  register Sinatra::Namespace
  helpers Sinatra::Streaming
  
  namespace '/api/v2/packages' do
    # POST of packages
    post '/?' do
      began_at = Time.now.utc
      log_message = 'GtkApi::POST /api/v2/packages/?'
      logger.info(log_message) {"entered with params=#{params}"}
      content_type :json
    
      if params[:package].nil?
        count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, "No package file specified: #{params}", log_message
      end
      
      if params[:package][:tempfile].nil?
        count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'Temp file name not provided', log_message
      end

      token = get_token( request.env, log_message)
      if (token.nil? || token.empty?)
        count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'Token not provided', log_message
      end
        
      begin
        resp = PackageManagerService.create(params.merge({token: token}))
        logger.debug(log_message) {"resp=#{resp.inspect}"}
        case resp[:status]
        when 201
          logger.info(log_message) {"leaving with package: #{resp[:data][:uuid]}"}
          count_package_on_boardings(labels: {result: "ok", uuid: resp[:data][:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
          headers 'Location'=> PackageManagerService.class_variable_get(:@@url)+"/packages/#{resp[:data][:uuid]}", 'Content-Type'=> 'application/json'
          halt 201, resp[:data].to_json
        when 400
          count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
          json_error 400, "Error creating package #{params}", log_message
        when 403
          count_package_on_boardings(labels: {result: "forbidden", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
          json_error 403, "User not allowed to create package #{params}", log_message
        when 404
          count_package_on_boardings(labels: {result: "not found", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
          json_error 404, "User name not found", log_message
        when 409
          logger.error(log_message) {"leaving with duplicated package: #{resp[:data]}"}
          count_package_on_boardings(labels: {result: "duplicated", uuid: resp[:data][:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
          halt 409, resp[:data].to_json
        else
          count_package_on_boardings(labels: {result: "other error", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
          json_error resp[:status], "Unknown status: #{resp[:status]} for package #{params}", log_message
        end
      rescue ArgumentError => e
        count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, "Error creating package #{params}", log_message
      end
    end

  # GET a specific package
    get '/:uuid/?' do
      began_at = Time.now.utc
      log_message = 'GtkApi::GET /api/v2/packages/:uuid/?'
      logger.debug(log_message) {'entered'}
      content_type :json
      unless params[:uuid].nil?
        logger.debug(log_message) {"params[:uuid]=#{params[:uuid]}"}
        json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
        package = PackageManagerService.find_by_uuid(params[:uuid])
        if package
          logger.debug(log_message) {"leaving with package #{package}"}
          count_single_package_queries(labels: {result: "ok", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
          content_type :json #headers 'Content-Type'=> 'application/json'
          halt 200, package.to_json
        else
          count_single_package_queries(labels: {result: "not found", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
          json_error 404, "No package with UUID=#{params[:uuid]} was found", log_message
        end
      end
      count_single_package_queries(labels: {result: "bad request", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
      json_error 400, 'No package UUID specified', log_message     
    end
  
    # GET a specific package's file
      get '/:uuid/download/?' do
        began_at = Time.now.utc
        log_message = 'GtkApi::GET /api/v2/packages/:uuid/download/?'
        logger.debug(log_message) {'entered with uuid='+params['uuid']}
        unless params[:uuid].nil?
          logger.debug(log_message) {"params[:uuid]=#{params[:uuid]}"}
          json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
          package = PackageManagerService.find_by_uuid(params[:uuid])
          if package
            logger.debug(log_message) {"Found package #{package}"}
            logger.debug(log_message) {"Looking for the package file name for package file #{package[:son_package_uuid]}..."}
            file_name = PackageManagerService.download(package[:son_package_uuid])
            count_package_downloads(labels: {result: "ok", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
            send_file file_name
          else
            count_package_downloads(labels: {result: "not found", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
            json_error 404, "No package with UUID=#{params[:uuid]} was found", log_message
          end
        end
        count_package_downloads(labels: {result: "bad request", uuid: params[:uuid], elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'No package UUID specified', log_message    
      end

    # GET potentially many packages
    get '/?' do
      log_message = 'GtkApi::GET /api/v2/packages/?'
      logger.debug(log_message) {'entered with '+query_string}
      content_type :json
    
      @offset ||= params[:offset] ||= DEFAULT_OFFSET
      @limit ||= params[:limit] ||= DEFAULT_LIMIT

      token = get_token( request.env, log_message)
      if (token.nil? || token.empty?)
        count_package_on_boardings(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'Token not provided', log_message
      end
    
      packages = PackageManagerService.find(params)
      if packages
        logger.debug(log_message) { "leaving with #{packages}"}
        # TODO: total must be returned from the PackageManagement service
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: packages.size)
        headers 'Content-Type'=>'application/json', 'Link'=> links
        halt 200, packages.to_json
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
  
  def count_package_on_boardings(labels:)
    name = __method__.to_s.split('_')[1..-1].join('_')
    desc = "how many packages have been on-boarded"
    PackageManagerService.counter_kpi({name: name, docstring: desc, base_labels: labels.merge({method: 'POST', module: 'packages'})})
  end
  def count_package_downloads(labels:)
    name = __method__.to_s.split('_')[1..-1].join('_')
    desc = "how many package file downloads have been requested"
    PackageManagerService.counter_kpi({name: name, docstring: desc, base_labels: labels.merge({method: 'GET', module: 'packages'})})
  end
  
  def count_single_package_queries(labels:)
    name = __method__.to_s.split('_')[1..-1].join('_')
    desc = "how many single package have been requested"
    PackageManagerService.counter_kpi({name: name, docstring: desc, base_labels: labels.merge({method: 'GET', module: 'packages'})})
  end
end
