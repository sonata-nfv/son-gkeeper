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
      logger.debug "GtkSrv: GET /service: #{service}"
      response = service.to_json
      logger.debug "GtkSrv: leaving GET /services/#{params[:uuid]} with response="+response
      halt 200, response
    else
      logger.debug "GtkSrv: leaving GET /services/#{params[:uuid]} with \"No service with uuid #{params[:uuid]} was found\""
      json_error 404, "No service with uuid #{params[:uuid]} was found"
    end
  end

  get '/admin/logs' do
    logger.debug "GtkSrv: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end  
end
