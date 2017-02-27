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
require 'sinatra/namespace'
class GtkApi < Sinatra::Base
  
  register Sinatra::Namespace
  
  namespace '/api/v2/records' do
    before do
      if request.request_method == 'OPTIONS'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST,PUT'      
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
        halt 200
      end
  	end

    # GET many instances
    get '/:kind/?' do
      log_message = "GtkApi::GET /api/v2/records/#{params[:kind]}"
      params.delete('splat')
      params.delete('captures')
      logger.debug(log_message) {'entered with query parameters '+query_string}
  
      @offset ||= params[:offset] ||= DEFAULT_OFFSET 
      @limit ||= params[:limit] ||= DEFAULT_LIMIT
  
      records = RecordManagerService.find_records(params)
      case records[:status]
      when 200
        logger.debug(log_message) {"leaving with #{records}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: records[:count])
        headers 'Link' => links
        halt 200, records[:items].to_json
      else
        logger.debug(log_message) {"No #{params[:kind]} records found"}
        halt 404, '[]'
      end
    end

    # GET a specific instance
    get '/:kind/:uuid/?' do
      method = "GtkApi::GET /api/v2/records/#{params[:kind]}/#{params[:uuid]}: "
      unless params[:uuid].nil?
        logger.debug(method) {'entered'}
        json_error 400, 'Invalid Instance UUID' unless valid? params[:uuid]
        record = RecordManagerService.find_record_by_uuid(params[:uuid])
        case record[:status]
        when 200
          logger.debug(log_message) {"leaving with #{record}"}
          halt 200, record[:items].to_json
        else
          logger.debug(log_message) {"No #{params[:kind]} record with uuid #{params[:uuid]} found"}
          halt 404, "No #{params[:kind]} record with uuid #{params[:uuid]} found"
        end
      end
      logger.debug(method) {"leaving with \"No instance UUID specified\""}
      json_error 400, 'No instance UUID specified'
    end
  
    # PUT service instance
    put '/services/:uuid/?' do
      method = "GtkApi::PUT /api/v2/records/services/#{params[:uuid]}"
      unless params[:uuid].nil?
        logger.debug(method) {'entered'}
        json_error 400, method + ": Invalid Instance UUID=#{params[:uuid]}" unless valid? params[:uuid]

        # the body of the request is exepected to contain the NSD UUID and the NSD's latest version      
        body_params = JSON.parse(request.body.read)
        logger.debug(method) {"body_params=#{body_params}"}
        unless body_params.key?('nsd_id') && body_params.key?('latest_nsd_id')
          message = 'Both :nsd_id and :latest_nsd_id must be present'
          logger.debug(method) {"Leaving with \"#{message}\""}
          halt 404, message
        end
      
        # here we have the 
        descriptor = RecordManagerService.find_service_by_uuid(body_params['latest_nsd_id'])
        if descriptor
          logger.debug(method) {"found #{descriptor}"}

          update_request = ServiceManagerService.create_service_update_request(nsr_uuid: params[:uuid], nsd: descriptor)
          if update_request
            logger.debug(method) { "update_request =#{update_request}"}
            halt 201, update_request.to_json
          else
            message = 'No request was created'
            logger.debug(method) { "leaving with #{message}"}
            json_error 400, message
          end
        else
          message = "No descriptor with uuid=#{params[:latest_nsd_id]} found"
          logger.debug(method) {"leaving with \"#{message}\""}
          halt 404, message
        end
      end
      message = 'No instance UUID specified'
      logger.debug(method) {"leaving with \"#{message}\""}
      json_error 400, message
    end
  end
  
  namespace '/api/v2/admin/records' do
    # GET module's logs
    get '/logs/?' do
      log_message = "GtkApi::GET /api/v2/admin/records/logs"
      logger.debug(log_message) {"entered"}
      url = RecordManagerService.class_variable_get(:@@url)+'/admin/logs'
      log = RecordManagerService.get_log(url: url, log_message:log_message)
      logger.debug(log_message) {'leaving with log='+log}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      halt 200, log #.to_s
    end
  end
end
