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
  helpers GtkApiHelper
  
  namespace '/api/v2/services' do
    #options '/' do
    before do
      if request.request_method == 'OPTIONS'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST,PUT'      
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
        halt 200
      end
    end
    
    # GET many services
    get '/?' do
      log_message = MODULE+' GET /api/v2/services'
    
      logger.debug(log_message) {'entered with '+query_string}
    
      @offset ||= params['offset'] ||= DEFAULT_OFFSET
      @limit ||= params['limit'] ||= DEFAULT_LIMIT
      logger.debug(log_message) {"offset=#{@offset}, limit=#{@limit}"}
      logger.debug(log_message) {"params=#{params}"}
    
      services = ServiceManagerService.find_services(params)
      logger.debug(log_message) {"Found services #{services}"}
      case services[:status]
      when 200
        logger.debug(log_message) {"links: request_url=#{request_url}, limit=#{@limit}, offset=#{@offset}, total=#{services[:count]}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: services[:count].to_i)
        logger.debug(log_message) {"links: #{links}"}
        headers 'Link'=> links, 'Record-Count'=> services[:count].to_s
        status 200
        halt services[:items].to_json
      else
        message = "No services with #{params} were found"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
  
    # GET a specific service
    get '/:uuid/?' do
      log_message = MODULE+' GET /api/v2/services/:uuid'
      logger.debug(log_message) {"entered with #{params}"}
    
      if valid?(params[:uuid])
        uuid = params[:uuid]
        
        # TODO: mind that, besides the URL-based uuid we might as well pass other params, like fields we want to show
        #params.delete :uuid
        service = ServiceManagerService.find_service_by_uuid(uuid: uuid) #, params: params)
        if service[:count] && !service[:items].empty?
          logger.debug(log_message) {"leaving with #{service}"}
          halt 200, service.to_json
        else
          logger.debug(log_message) {"leaving with message 'Service #{params[:uuid]} not found'"}
          json_error 404, "Service #{params[:uuid]} not found"
        end
      else
        message = "Service #{params[:uuid]} not valid"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
  end
  
  namespace '/api/v2/admin/services' do
    get '/logs/?' do
      log_message = 'GtkApi::GET /admin/services/logs'
      logger.debug(log_message) {'entered'}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      url = ServiceManagerService.class_variable_get(:@@url)+'/admin/logs'
      log = ServiceManagerService.get_log(url: url, log_message:log_message)
      logger.debug(log_message) {'leaving with log='+log}
      halt 200, log
    end
  end
end
