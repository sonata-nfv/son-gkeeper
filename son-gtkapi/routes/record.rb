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
  
  # GET many instances
  get '/records/:kind/?' do
    method = MODULE + "GET /records/#{params[:kind]}"
    params.delete('splat')
    params.delete('captures')
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug(method) {"entered with query parameters '#{uri.query}'"}
    
    params[:offset] ||= DEFAULT_OFFSET 
    params[:limit] ||= DEFAULT_LIMIT
    
    records = settings.record_management.find_records(params)
    if records
      logger.debug(method) {"leaving with #{records}"}
      halt 200, records.to_json
    else
      logger.debug(method) {"No #{params[:kind]} records found"}
      halt 404, "No #{params[:kind]} records found"
    end
  end
  
  # GET a specific instance
  get '/records/:kind/:uuid/?' do
    method = MODULE + "GET /records/#{params[:kind]}/#{params[:uuid]}: "
    unless params[:uuid].nil?
      logger.debug(method) {'entered'}
      json_error 400, 'Invalid Instance UUID' unless valid? params[:uuid]
    end
    logger.debug(method) {"leaving with \"No instance UUID specified\""}
    # TODO!!
    json_error 400, 'No instance UUID specified'
  end
  
  # PUT service instance
  put '/records/services/:uuid/?' do
    method = MODULE + "PUT /records/services/#{params[:uuid]}: "
    unless params[:uuid].nil?
      logger.debug(method) {'entered'}
      json_error 400, method + "Invalid Instance UUID=#{params[:uuid]}" unless valid? params[:uuid]

      record = settings.record_management.find_service_by_uuid(params[:uuid])
      if record
        logger.debug(method) {"found #{record}"}
        # TODO: from here on, a request must be submited to the MANO Framework
        update_request = settings.record_management.create_service_update_request(params)
        if update_request
          logger.debug(method) { "PUT /records/services/#{params[:uuid]}: update_request =#{update_request}"
          halt 201, update_request.to_json
        else
          message = 'No request was created'
          logger.debug(method) { "leaving PUT /records/services/#{params[:uuid]} with #{message}"}
          json_error 400, message
        end
      else
        message = "No record with uuid=#{params[:uuid]} found"
        logger.debug(method) {"leaving with \"#{message}\""}
        halt 404, message
      end
    end
    message = 'No instance UUID specified'
    logger.debug(method) {"leaving with \"#{message}\""}
    json_error 400, message
  end
  
  # GET module's logs
  get '/admin/records/logs' do
    method = MODULE + "GET /admin/records/logs: "
    logger.debug(method) {"entered"}
    headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    log = settings.record_management.get_log
    halt 200, log.to_s
  end
end
