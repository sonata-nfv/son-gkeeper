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
  namespace '/api/v2' do
    
    # GET licence types
    get '/licence-types/?' do
      MESSAGE = 'GtkApi::GET /api/v2/licence-types/?'
      
      logger.debug(log_message) {"entered with #{query_string}"}
      
      @offset ||= params['offset'] ||= DEFAULT_OFFSET 
      @limit ||= params['limit'] ||= DEFAULT_LIMIT
    
      licence_types = settings.licence_management.find_licence_types(params)
      if licence_types
        logger.debug(MESSAGE) {"leaving with #{licence_types}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: licence_types.size)
        [200, {'Link' => links}, licence_types.to_json]
      else
        ERROR_MESSAGE = "No licence types with #{params} were found"
        logger.debug(MESSAGE) {"leaving with message '"+ERROR_MESSAGE+"'"}
        json_error 404, ERROR_MESSAGE
      end
    end

    # GET many licences
    get '/licences/?' do
      # TODO
      MESSAGE = 'GtkApi::GET /api/v2/licences/?'
    
      logger.debug(MESSAGE) {"entered with "+query_string}
      logger.debug(MESSAGE) {"Settings Srv. Mgmt. = #{settings.service_management.class}"}
    
      @offset ||= params['offset'] ||= DEFAULT_OFFSET 
      @limit ||= params['limit'] ||= DEFAULT_LIMIT
    
      licences = settings.service_management.find_services(params)
      if licences
        logger.debug(MESSAGE) {"leaving with #{licences}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: licences.size)
        [200, {'Link' => links}, licences.to_json]
      else
        ERROR_MESSAGE = "No services with #{params} were found"
        logger.debug(MESSAGE) {"leaving with message '"+ERROR_MESSAGE+"'"}
        json_error 404, ERROR_MESSAGE
      end
    end
  
    # GET a specific licence
    get '/licences/:uuid/?' do
      log_message = MODULE+' GET /api/v2/services/:uuid'
      logger.debug(log_message) {"Settings Srv. Mgmt. = #{settings.service_management.class}"}
      logger.debug(log_message) {"entered with #{params[:uuid]}"}
    
      if valid?(params[:uuid])
        service = settings.service_management.find_service_by_uuid(params[:uuid])
        if service
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
  
    get '/api/v2/admin/licences/logs' do
      logger.debug "GtkApi: entered GET /api/v2/admin/licences/logs"
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/api/v2/admin/licences/logs'
      log = settings.licence_management.get_log
      halt 200, log
    end
    
  private 
  def query_string
    request.env['QUERY_STRING'].nil? ? '' : '?' + request.env['QUERY_STRING'].to_s
  end

  def request_url
    request.env['rack.url_scheme']+'://'+request.env['HTTP_HOST']+request.env['REQUEST_PATH']
  end
end
