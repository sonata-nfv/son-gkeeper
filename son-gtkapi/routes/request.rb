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
require 'addressable/uri'

class GtkApi < Sinatra::Base
  
  before do
	  if request.request_method == 'OPTIONS'
		response.headers["Access-Control-Allow-Origin"] = "*"
		response.headers["Access-Control-Allow-Methods"] = "POST"

		halt 200
	  end
	end
  
  # POST a request
  post '/requests/?' do
    unless params[:service_uuid].nil?
      logger.debug "GtkApi: POST /requests with :service_uuid="+params[:service_uuid]
      request = ServiceManagerService.create(params)
      if request
        logger.debug "GtkApi: POST /requests: request =#{request}"
        halt 201, request.to_json
      else
        logger.debug "GtkApi: leaving POST /requests with 'No request was created'"
        json_error 400, 'No request was created'
      end
    end
    logger.debug "GtkApi: leaving POST /requests with 'No service id specified for the request'"
    json_error 400, 'No service id specified for the request'
  end

  # GET many requests
  get '/requests/?' do
    uri = Addressable::URI.new
    params['offset'] ||= DEFAULT_OFFSET 
    params['limit'] ||= DEFAULT_LIMIT
    uri.query_values = params
    logger.info "GtkApi: entered GET /requests?#{uri.query}"
    
    requests = JSON.parse(ServiceManagerService.find_requests(params))
    logger.info "GtkApi: requests=#{requests}"
    if requests && requests.is_a?(Array)
      logger.info "GtkApi: leaving GET /requests?#{uri.query} with #{requests}"
      halt 200, requests.to_json
    else
      logger.info "GtkApi: leaving GET /requests?#{uri.query} with 'No requests were found'"
      json_error 400, 'No requests were found'
    end
  end
  
  # GET one specific request
  get '/requests/:uuid/?' do
    unless params[:uuid].nil?
      logger.debug "GtkApi: GET /requests/#{params[:uuid]}"
      json_error 400, 'Invalid request UUID' unless valid? params[:uuid]
      
      request = ServiceManagerService.find_requests_by_uuid(params['uuid'])
      json_error 404, "The request UUID #{params[:uuid]} does not exist" unless request

      logger.debug "GtkApi: leaving GET /requests/#{params[:uuid]}\" with request #{request}"
      halt 200, request.to_json
    end
    logger.debug "GtkApi: leaving GET /requests/#{params[:uuid]} with 'No requests UUID specified'"
    json_error 400, 'No requests UUID specified'
  end
  
end
