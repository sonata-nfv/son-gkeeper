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
require 'yaml'
require 'bunny'

class GtkSrv < Sinatra::Base  
  
  # GETs a request, given an uuid
  get '/requests/:uuid/?' do
    logger.debug(MODULE) {" entered GET /requests/#{params[:uuid]}"}
    request = Request.find(params[:uuid])
    json_request = json(request, { root: false })
    halt 206, json_request if request
    json_error 404, "#{MODULE}: Request #{params[:uuid]} not found"    
  end
  
  
  # GET many requests
  get '/requests/?' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info(MODULE) {" entered GET /requests?#{uri.query}"}
    logger.info(MODULE) {" params=#{params}"}
    
    # transform 'string' params Hash into keys
    keyed_params = keyed_hash(params)
    
    # get rid of :offset and :limit
    [:offset, :limit].each { |k| keyed_params.delete(k)}
    valid_fields = [:service_uuid, :status, :created_at, :updated_at]
    logger.info(MODULE) {" keyed_params.keys - valid_fields = #{keyed_params.keys - valid_fields}"}
    json_error 400, "GtkSrv: wrong parameters #{params}" unless keyed_params.keys - valid_fields == []
    
    requests = Request.where(keyed_params).limit(params['limit'].to_i).offset(params['offset'].to_i)
    json_requests = json(requests, { root: false })
    logger.info(MODULE) {" leaving GET /requests?#{uri.query} with "+json_requests}
    halt 200, json_requests if json_requests
    json_error 404, 'GtkSrv: No requests were found'
  end

  # POSTs an instantiation request, given a service_uuid
  post '/requests/?' do
    original_body = request.body.read
    logger.info(MODULE) {" entered POST /requests with original_body=#{original_body}"}
    params = JSON.parse(original_body, :quirks_mode => true)
    logger.info(MODULE) {" POST /requests with params=#{params}"}
    
    begin
      start_request={}
      
      #start_request['app_id']='son-gatekeeper'
      si_request = Request.create(params)
      logger.info('GtkSrv: POST /requests') { "with service_uuid=#{params['service_uuid']}: #{si_request.inspect}"}
      service = NService.new(settings.services_catalogue, logger).find_by_uuid(params['service_uuid'])
      if service
        service.delete(:status) if service[:status]
        service.delete('status') if service['status']
        #service.delete(:uuid) if service[:uuid]
        #service.delete('uuid') if service['uuid']
        
        start_request['NSD']=service
        logger.debug('GtkSrv: POST /requests') { "service=#{service}"}
      
        service['network_functions'].each_with_index do |function, index|
          logger.debug('GtkSrv: POST /requests') { "function=[#{function['vnf_name']}, #{function['vnf_vendor']}, #{function['vnf_version']}]"}
          vnfd = VFunction.new(settings.functions_catalogue, logger).find_function(function['vnf_name'],function['vnf_vendor'],function['vnf_version'])
          logger.debug('GtkSrv: POST /requests') {"function#{index}=#{vnfd}"}
          if vnfd[0]
            vnfd[0].delete(:status) if vnfd[0][:status]
            vnfd[0].delete('status') if vnfd[0]['status']
            #vnfd[0].delete(:uuid) if vnfd[0][:uuid]
            #vnfd[0].delete('uuid') if vnfd[0]['uuid']
          
            start_request["VNFD#{index}"]=vnfd[0]  
            logger.debug('GtkSrv: POST /requests') {"start_request[\"VNFD#{index}\"]=#{vnfd[0]}"}
          else
            logger.error('GtkSrv: POST /requests') {"network function not found"}
          end
        end
            
        start_request_yml = YAML.dump(start_request)
        logger.debug "GtkSrv: POST /requests #{params}: "+start_request_yml

        smresponse = settings.mqserver.publish( start_request_yml.to_s, si_request['id'])
        json_request = json(si_request, { root: false })
        logger.info(MODULE) {' returning POST /requests with request='+json_request}
        halt 201, json_request
      else
        logger.error('GtkSrv: POST /requests') {"network service not found"}
      end
    rescue Exception => e
      logger.debug(e.message)
	    logger.debug(e.backtrace.inspect)
	    halt 500, 'Internal server error'
    end
  end

  # PUTs an update on an existing instantiation request, given its UUID
  put '/requests/:uuid/?' do
    logger.debug "GtkSrv: entered PUT /requests with params=#{params}"
    @request = Request.find params[:uuid]
    
    if @request.update_all(params)
      logger.debug "GtkSrv: returning PUT /requests with updated request=#{@request}"
      halt 200, @request.to_json
    else
      logger.debug "GtkSrv: returning PUT /requests with 'GtkSrv: Not possible to update the request'"
      json_error 400, 'GtkSrv: Not possible to update the request'
    end 
  end  
end
