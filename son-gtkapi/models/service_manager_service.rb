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
require './models/manager_service.rb'

class ServiceManagerService < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
    
  def self.config(url:)
    method = LOG_MESSAGE + "#config"
    raise ArgumentError.new('ServiceManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('ServiceManagerService can not be configured with empty url') if url.empty?
    @@url = url
    GtkApi.logger.debug(method) {"entered with url=#{url}"}
  end

  def self.find_service_by_uuid(uuid:, params: {})
    find(url: @@url + '/services/' + uuid, params: params, log_message: LOG_MESSAGE + "##{__method__}(#{uuid})")
  end
  
  def self.find_services(params)
    log_message = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(log_message) {'entered'}
    services=find(url: @@url + '/services', params: params, log_message: LOG_MESSAGE + "##{__method__}(#{params})")
    vectorize_hash services
 end

  def self.find_requests(params)
    log_message = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(log_message) {'entered'}
    requests=find(url: @@url + '/requests', params: params, log_message: LOG_MESSAGE + "##{__method__}(#{params})")
    vectorize_hash requests
  end
  
  def self.find_requests_by_uuid(uuid)
    log_message = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(log_message) {'entered'}
    find(url: @@url + '/requests/' + uuid, log_message: LOG_MESSAGE + "##{__method__}(#{uuid})")
  end
  
  def self.create_service_intantiation_request(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}

    begin
      GtkApi.logger.debug(method) {"@url = "+@@url}
      response = self.postCurb(url: @@url+'/requests', body: params.to_json) ## TODO: check if this tests ok!! 
      GtkApi.logger.debug(method) {"response=#{response}"}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil 
    end      
  end
  
  def self.create_service_update_request(nsr_uuid:, nsd:)
    message = LOG_MESSAGE+'.create_service_update_request'
    GtkApi.logger.debug(message) {'entered'}
    GtkApi.logger.debug(message) {"service instance=#{nsr_uuid}, nsd=#{nsd}"}
    begin
      GtkApi.logger.debug(message) {"@url = "+@@url}
      #response = RestClient.put(@url+'/services/'+nsr_uuid, nsd.to_json, content_type: :json, accept: :json) 
      response = self.postCurb(url: @@url+'/services/'+nsr_uuid, body: nsd.to_json) 
      GtkApi.logger.debug(message) {"response="+response}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil 
    end      
  end
  
  # TODO
  def self.valid?(user)
    true
  end
end
