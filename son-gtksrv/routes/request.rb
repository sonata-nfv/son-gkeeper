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
require 'yaml'
require 'bunny'

class GtkSrv < Sinatra::Base  
  
  # GETs a request, given an uuid
  get '/requests/:uuid/?' do
    log_msg = 'GtkSrv::GET /requests'.freeze
    logger.debug(log_msg) {" entered GET /requests/#{params[:uuid]}"}
    request = Request.find(params[:uuid])
    json_request = json(request, { root: false })
    halt 200, json_request if request
    json_error 404, "#{log_msg}: Request #{params[:uuid]} not found"    
  end

  # GET many requests
  get '/requests/?' do
    log_msg = 'GtkSrv::GET /requests'.freeze

    logger.info(log_msg) {" entered GET /requests#{query_string}"}
    logger.info(log_msg) {" params=#{params}"}
    
    # transform 'string' params Hash into keys
    keyed_params = keyed_hash(params)
    
    # get rid of :offset and :limit
    [:offset, :limit, :captures].each { |k| keyed_params.delete(k)}
    valid_fields = [:service_uuid, :status, :created_at, :updated_at]
    logger.info(log_msg) {" keyed_params.keys - valid_fields = #{keyed_params.keys - valid_fields}"}
    json_error 400, "GtkSrv: wrong parameters #{params}" unless keyed_params.keys - valid_fields == []
    
    requests = Request.where(keyed_params).limit(params['limit'].to_i).offset(params['offset'].to_i)
    json_requests = json(requests, { root: false })
    logger.info(log_msg) {" leaving GET /requests#{query_string} with "+json_requests}
    logger.info(log_msg) {" size is #{requests.size}"}
    if json_requests
      headers 'Record-Count'=>requests.size.to_s, 'Content-Type'=>'application/json'
      halt 200, json_requests
    end
    json_error 404, 'GtkSrv: No requests were found'
  end

  # POSTs an instantiation request, given a service_uuid
  post '/requests/?' do
    log_msg = 'GtkSrv::POST /requests'.freeze
    original_body = request.body.read

    params = JSON.parse(original_body, quirks_mode: true, symbolize_names: true)
    logger.debug(log_msg) {"with params=#{params}"}

    begin
      resp = Processor.new(logger, settings.services_catalogue, settings.functions_catalogue).call(params)
      json_request = json(resp, { root: false })

      logger.debug(log_msg) {' returning POST /requests with request='+json_request}
      halt 201, json_request
    rescue Exception => e
      logger.error(log_msg) {e.message}
	    logger.error(log_msg) {e.backtrace.inspect}
	    json_error 400, 'Not found: '+e.message
    end
  end
  
  private 
  
  def find_mq_server(request_type)
    case request_type
    when 'CREATE'
      settings.create_mqserver
    when 'UPDATE'
      settings.update_mqserver
    # TERMINATE is processed above 
    #when 'TERMINATE'
    #   settings.terminate_mqserver
    else
      json_error 400, "#{request_type} is the wrong type of request"
    end
  end
  
  def query_string
    request.env['QUERY_STRING'].nil? ? '' : '?' + request.env['QUERY_STRING'].to_s
  end

  def request_url
    log_message = 'GtkSrv::request_url'
    logger.debug(log_message) {"Schema=#{request.env['rack.url_scheme']}, host=#{request.env['HTTP_HOST']}, path=#{request.env['REQUEST_PATH']}"}
    request.env['rack.url_scheme']+'://'+request.env['HTTP_HOST']+request.env['REQUEST_PATH']
  end
end
