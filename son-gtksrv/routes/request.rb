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
    logger.debug "GtkSrv: entered GET /requests/#{params[:uuid]}"
    request = Request.find(params[:uuid])
    json_request = json(request, { root: false })
    halt 206, json_request if request
    json_error 404, "GtkSrv: Request #{params[:uuid]} not found"    
  end
  
  
  # GET many requests
  get '/requests/?' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info "GtkSrv: entered GET /requests?#{uri.query}"
    logger.info "GtkSrv: params=#{params}"
    
    # transform 'string' params Hash into keys
    keyed_params = keyed_hash(params)
    
    # get rid of :offset and :limit
    [:offset, :limit].each { |k| keyed_params.delete(k)}
    valid_fields = [:service_uuid, :status, :created_at, :updated_at]
    logger.info "GtkSrv: keyed_params.keys - valid_fields = #{keyed_params.keys - valid_fields}"
    json_error 400, "GtkSrv: wrong parameters #{params}" unless keyed_params.keys - valid_fields == []
    
    requests = Request.where(keyed_params).limit(params['limit'].to_i).offset(params['offset'].to_i)
    json_requests = json(requests, { root: false })
    logger.info "GtkSrv: leaving GET /requests?#{uri.query} with "+json_requests
    halt 200, json_requests if json_requests
    json_error 404, 'GtkSrv: No requests were found'
  end

  # POSTs an instantiation request, given a service_uuid
  post '/requests/?' do
    logger.info "GtkSrv: entered POST /requests with params=#{params}"
    
    begin
      logger.debug "GtkSrv: entered POST /requests with service uuid=#{params[:service_uuid]}"
      request = Request.create(:service_uuid => params[:service_uuid])
      service = JSON.parse(NService.find_services_by_uuid(params[:service_uuid]))
      start_request=Hash.new
      start_request['NSD']=service
      
      service['network_functions'].each_with_index do |nfd, index| 
        complete_nfd=JSON.parse(VFunction.find_function(nfd['vnf_name'],nfd['vnf_vendor'],nfd['vnf_version']))
        complete_nfd=complete_nfd[0]
        start_request["VNFD#{index}"]=complete_nfd  
      end
            
      start_request_yml = YAML.dump(start_request)
      logger.debug(start_request_yml)
      
      #generate_token
      #request['request_uuid']=SecureRandom.uuid
      #request.save
      mq_server = MQServer.new(GtkSrv.mqserver['url'],logger)
      #smresponse = mq_server.call_sm(start_request_yml,request['id'])
      smresponse = mq_server.emit(start_request_yml.to_s,request['id'])
      json_request = json(request, { root: false })
      logger.info 'GtkSrv: returning POST /requests with request='+json_request
      halt 201, json_request
      
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
