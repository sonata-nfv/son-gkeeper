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

class GtkSrv < Sinatra::Base

  get '/services/?' do
    logger.debug "GtkSrv: entered GET /services with params #{params}"
    uri = Addressable::URI.new

    # Remove list of wanted fields from the query parameter list
    field_list = params.delete('fields')
    uri.query_values = params
    logger.debug 'GtkSrv: GET /services: uri.query='+uri.query
    logger.debug "GtkSrv: GET /services: params=#{params}"
    
    services = NService.new(settings.services_catalogue, logger).find(params)
    if services
      logger.debug "GtkSrv: GET /services: #{services}"

      if field_list
        fields = field_list.split(',')
        logger.debug "GtkSrv: GET /services: fields=#{fields}"
        response = services.to_json(:only => fields)
      else
        response = services.to_json
      end
      logger.debug "GtkSrv: leaving GET /services?#{uri.query} with response="+response
      halt 200, response
    else
      logger.debug "GtkSrv: leaving GET /services?#{uri.query} with \"No service with params #{uri.query} was found\""
      json_error 404, "No service with params #{uri.query} was found"
    end
  end
  
  get '/services/:uuid' do
    logger.debug "GtkSrv: entered GET /services/#{params[:uuid]}"
    
    service = NService.new(settings.services_catalogue, logger).find_by_uuid(params[:uuid])
    if service
      logger.debug "GtkSrv: GET /services: #{service}"
      response = service.to_json
      logger.debug "GtkSrv: leaving GET /services/#{params[:uuid]} with response="+response
      halt 200, response
    else
      logger.debug "GtkSrv: leaving GET /services/#{params[:uuid]} with \"No service with uuid #{params[:uuid]} was found\""
      json_error 404, "No service with uuid #{params[:uuid]} was found"
    end
  end

  # PUTs an update on an existing service instance, given the service instance UUID
  put '/services/:uuid/?' do
    method = MODULE + " PUT /services/#{params[:uuid]}"
    logger.debug(method) {"called"}
    
    # We are assuming that:
    # UUID is not null and is a valid UUID

    # is it a valid service instance uuid?
    begin
      valid = Request.validate_request(service_instance_uuid: params[:uuid], logger: logger)
      logger.debug(method) {"valid=#{valid.inspect}"}
    
      if valid
        nsd = JSON.parse(request.body.read, :quirks_mode => true)
        logger.debug(method) {"with nsd=#{nsd}"}

        #nsd.delete(:status) if nsd[:status]
        nsd.delete('status') if nsd['status']
        update_response = Request.process_request(nsd: nsd, service_instance_uuid: params[:uuid], update_server: settings.update_server, logger: logger)
        logger.debug(method) {"update_response=#{update_response}"}
        if update_response
          halt 201, update_response.to_json
        else
          error_msg = "Update request for service instance '#{params[:uuid]} failled"
          logger.debug(method) {"leaving with '#{error_msg}"}
          json_error 400, error_msg
        end
      else
        error_msg = "Service instance '#{params[:uuid]} not 'READY'"
        logger.debug(method) {"leaving with '#{error_msg}"}
        json_error 400, error_msg
      end
    rescue Exception=> e
      error_msg = "Service instance '#{params[:uuid]} not found"
      logger.debug(method) {"leaving with '#{error_msg}"}
      json_error 404, error_msg
    end
  end

  get '/admin/logs' do
    logger.debug "GtkSrv: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end  
end
