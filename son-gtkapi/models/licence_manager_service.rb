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

class LicenceManagerService < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def self.config(url:, logger:)
    method = LOG_MESSAGE + "#config(url=#{url}, logger=#{logger})"
    raise ArgumentError.new('LicenceManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('LicenceManagerService can not be configured with empty url') if url.empty?
    raise ArgumentError.new('LicenceManagerService can not be configured with nil logger') if logger.nil?
    @@url = url
    @@logger = logger
    @@logger.debug(method) {'entered'}
  end

  def self.create_type(params)
    method = LOG_MESSAGE + "#create_type(params=#{params})"
    @@logger.debug(method) {'entered'}
    begin
      licence_type = postCurb(url: @@url+'/api/v1/types', body: params, logger: @@logger)
      @@logger.debug(method) {"licence_type=#{licence_type.body}"}
      JSON.parse licence_type.body
    rescue  => e #RestClient::Conflict
      @@logger.debug(method) {e.backtrace}
      {error: 'Licence type not created', licence_type: e.backtrace}
    end
  end
  
  # TODO
  def self.find_licence_by_uuid(uuid)
    method = LOG_MESSAGE + "#find_functions_by_uuid(#{uuid})"
    @@logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = uuid
    begin
      response = getCurb(url: @@url + "/functions/#{uuid}", headers: headers)
      # Shouldn't we parse before returning?
      #JSON.parse response.body
    rescue => e
      @@logger.error(method) {"e=#{e.backtrace}"}
      nil 
    end
  end
  
  def self.find_licence_types(params)
    method = LOG_MESSAGE + "#find_licence_types(#{params})"
    @@logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @@logger.debug(method) {"headers=#{headers}"}
    begin
      response = getCurb(urb: @@url + '/api/v1/types', headers: headers) 
      @@logger.debug(method) {"response=#{response}"}
      JSON.parse response.body
    rescue => e
      @@logger.error(method) {"e=#{e.backtrace}"}
      nil 
    end
  end
  
  def self.find_licences(params)
    method = LOG_MESSAGE + "#find_licences(#{params})"
    @@logger.debug(method) {'entered'}
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @@logger.debug(method) {"headers=#{headers}"}
    begin
      response = getCurb(urb: @@url + '/api/v1/licences', headers: headers) 
      @@logger.debug(method) {"response=#{response}"}
      JSON.parse response.body
    rescue => e
      @@logger.error(method) {"e=#{e.backtrace}"}
      nil 
    end
  end

  def self.get_log
    method = LOG_MESSAGE + "#get_log()"
    @@logger.debug(method) {'entered'}

    response=getCurb(url: @@url+'/admin/logs', headers: {'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'}, logger: @@logger)
    @@logger.debug(method) {'status=' + response.response_code.to_s}
    case response.response_code
      when 200
        response.body
      else
        @@logger.error(method) {'status=' + response.response_code.to_s}
        nil
      end
  end
  
  def self.url
    @@logger.debug(LOG_MESSAGE + "#url") {'@@url='+@@url}
    @@url
  end
end
