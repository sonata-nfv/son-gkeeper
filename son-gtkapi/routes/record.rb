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
  
  # GET many instances
  get '/records/nsrs/?' do
    method = 'GtkApi GET /records/nsrs'
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug(method) {"entered with #{uri.query}"}
    
    params[:offset] ||= DEFAULT_OFFSET 
    params[:limit] ||= DEFAULT_LIMIT
    
    records = settings.record_management.find_services(params)
    if records
      logger.debug(method) {"leaving with #{records}"}
      halt 200, records.to_json
    else
      logger.debug(method) {'No service records found'}
      halt 404, 'No service records found'
    end
  end
  
  # GET a specific instance
  get '/instances/:uuid/?' do
    unless params[:uuid].nil?
      logger.debug "GtkApi: entered GET /instances/#{params[:uuid]}"
      json_error 400, 'Invalid Instance UUID' unless valid? params['uuid']
    end
    logger.debug "GtkApi: leaving GET \"/instances/#{params[:uuid]}\" with \"No instance UUID specified\""
    json_error 400, 'No instance UUID specified'
  end
  
  get '/admin/instances/logs' do
    logger.debug "GtkApi: entered GET /admin/instances/logs"
    headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    log = settings.service_management.get_log
    halt 200, log.to_s
  end
end
