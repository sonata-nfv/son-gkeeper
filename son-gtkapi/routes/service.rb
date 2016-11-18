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
require 'addressable/uri'

class GtkApi < Sinatra::Base
  
  # GET many services
  get '/services/?' do
    log_message = MODULE+' GET /services'
    
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug(log_message) {"entered with #{uri.query}"}
    logger.debug(log_message) {"Settings Srv. Mgmt. = #{settings.service_management.class}"}
    
    params['offset'] ||= DEFAULT_OFFSET 
    params['limit'] ||= DEFAULT_LIMIT
    
    services = settings.service_management.find_services(params)
    if services
      logger.debug(log_message) {"leaving with #{services}"}
      halt 200, services.to_json
    else
      message = "No services with #{params} were found"
      logger.debug(log_message) {"leaving with message '"+message+"'"}
      json_error 404, message
    end
  end
  
  # GET a specific service
  get '/services/:uuid' do
    log_message = MODULE+' GET /services/:uuid'
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
  
  get '/admin/services/logs' do
    logger.debug "GtkApi: entered GET /admin/services/logs"
    headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    log = settings.service_management.get_log
    halt 200, log.to_s
  end
end
