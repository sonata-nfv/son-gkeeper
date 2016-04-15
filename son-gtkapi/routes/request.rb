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
  
  # POST a request
  post '/requests/?' do
    logger.debug "GtkApi: entered POST /requests"
    unless params[:service_id].nil?
      
    end
    logger.debug "GtkApi: leaving POST /requests with 'No service id specified for the request'"
    json_error 400, 'No service id specified for the request'
  end


  # GET many requests
  get '/requests' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkApi: entered GET /requests/#{uri.query}"
    
    # TODO: deal with offset and limit
    #offset = params[:offset]
    #limit = params[:limit]   
    
    requests = ServiceManagerService.find(params)
    logger.debug "GtkApi: leaving GET /requests/#{uri.query} with #{requests}"
    halt 200, requests.to_json if requests
    json_error 400, 'No requests were found'
  end
end
