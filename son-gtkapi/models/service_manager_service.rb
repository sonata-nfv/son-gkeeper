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
require './manager_service'

class ServiceManagerService < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def initialize(url, logger)
    method = LOG_MESSAGE + ".new(url=#{url}, logger=#{logger})"
    #@url = url
    #@logger = logger
    super
    @logger.debug(method){'entered'}
  end
    
  def find_service_by_uuid(uuid)
    method = LOG_MESSAGE + ".find_service_by_uuid(#{uuid})"
    @logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    begin
      #response = RestClient.get( @url+"/services/#{uuid}", headers)
      response = getCurb(@url+"/services/#{uuid}", headers)
      JSON.parse response.body
    rescue => e
      @logger.error(method) {"e=#{format_error(e.backtrace)}"}
      nil 
    end
  end
  
  def find_services(params)
    method = LOG_MESSAGE + ".find_services(#{params})"
    @logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @logger.debug(method) {"headers=#{headers}"}
    begin
      #response = RestClient.get(@url+'/services', headers) 
      response = getCurb(@url+'/services', headers) 
      @logger.debug(method) {"Leaving with response=#{response}"}
      JSON.parse response.body
    rescue => e
      @logger.error(method) {"#{e.message} - #{format_error(e.backtrace)}"}
      nil 
    end
  end

  def find_requests(params)
    method = LOG_MESSAGE + ".find_requests(#{params})"
    @logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @logger.debug(method) {"headers=#{headers}"}
    begin
      #response = RestClient.get(@url+'/requests', headers) 
      response = getCurb(@url+'/requests', headers) 
      JSON.parse response.body
    rescue => e
      @logger.error(method) {"#{e.message} - #{format_error(e.backtrace)}"}
      nil 
    end
  end
  
  def find_requests_by_uuid(uuid)
    method = LOG_MESSAGE + ".find_requests_by_uuid(#{uuid})"
    @logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = uuid
    begin
      #response = RestClient.get( @url+"/requests/#{uuid}", headers)
      response = getCurb(@url+'/requests/'+uuid, headers) 
      @logger.debug(method) {"response=#{response}"}
      JSON.parse response.body
    rescue => e
      @logger.error(method) {"#{e.message} - #{format_error(e.backtrace)}"}
      nil 
    end
  end
  
  def create_service_intantiation_request(params)
    method = LOG_MESSAGE + ".create_service_intantiation_request(#{params})"
    @logger.debug(method) {'entered'}

    begin
      @logger.debug(method) {"@url = "+@url}
      #response = RestClient.post(@url+'/requests', params.to_json, content_type: :json, accept: :json) 
      response = postCurb(@url+'/requests', params.to_json) ## TODO: check if this tests ok!! 
      @logger.debug(method) {"response="+response}
      parsed_response = JSON.parse(response)
      @logger.debug(method) {"parsed_response=#{parsed_response}"}
      parsed_response
    rescue => e
      @logger.error(method) {"#{e.message} - #{format_error(e.backtrace)}"}
      nil 
    end      
  end
  
  def create_service_update_request(nsr_uuid:, nsd:)
    message = LOG_MESSAGE+'.create_service_update_request'
    @logger.debug(message) {'entered'}
    @logger.debug(message) {"service instance=#{nsr_uuid}, nsd=#{nsd}"}
    begin
      @logger.debug(message) {"@url = "+@url}
      #response = RestClient.put(@url+'/services/'+nsr_uuid, nsd.to_json, content_type: :json, accept: :json) 
      response = postCurb(@url+'/services/'+nsr_uuid, nsd.to_json) 
      @logger.debug(message) {"response="+response}
      parsed_response = JSON.parse(response)
      @logger.debug(message) {"parsed_response=#{parsed_response}"}
      parsed_response
    rescue => e
      @logger.error(message) {"#{e.message} - #{format_error(e.backtrace)}"}
      nil 
    end      
  end
  
  def get_log
    method = LOG_MESSAGE+'get_log()'
    @logger.debug(method) {'entered'}
    full_url = @url+'/admin/logs'
    @logger.debug(method) {'url=' + full_url}
    getCurb(full_url)      
  end
end
