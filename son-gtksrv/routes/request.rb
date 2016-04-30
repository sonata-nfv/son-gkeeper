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
    
  # GETs a request, given an uuid
  get '/requests/:uuid/?' do
    logger.debug "GtkSrv: entered GET /requests/#{params[:uuid]}"
    request = Request.find(params[:uuid])
    halt 206, json(request) if request
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
    logger.info "GtkSrv: leaving GET /requests?#{uri.query} with #{requests.to_json}"
    halt 200, json(requests) if requests
    json_error 404, 'GtkSrv: No requests were found'
  end

  # POSTs an instantiation request, given a service_uuid
  post '/requests/?' do
    logger.info "GtkSrv: entered POST /requests with params=#{params}"
    
    begin
      request = Request.create(:service_uuid => params[:service_uuid])
      json_request = json request, { root: false }
      pp json_request
      logger.info 'GtkSrv: returning POST /requests with request='+json_request
      halt 201, json_request
    rescue e
      logger.info "GtkSrv: returning POST /requests with 'GtkSrv: Not possible to save the request'"
      json_error 400, 'GtkSrv: Not possible to save the request'
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

