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

class FunctionNotFoundError < StandardError; end

class FunctionManagerService < ManagerService
    
  #JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  attr_accessor :uuid, :instances
  
  def self.config(url:)
    log_message = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new('FunctionManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('FunctionManagerService can not be configured with empty url') if url.empty?
    @@url = url
    GtkApi.logger.debug(log_message) {'entered with url='+url}
  end

  def initialize(params)
    log_message = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(log_message) {"entered with params #{params}"}
    raise ArgumentError.new('FunctionManagerService can not be instantiated without a function uuid') unless (params.key?(:uuid) && !params[:uuid].empty?)
    @uuid = params[:uuid]
    @instances = params[:instances]
  end
  
  def self.find_by_uuid(uuid)
    find(url: @@url + '/functions/' + uuid, log_message: LOG_MESSAGE + "##{__method__}(#{uuid})")
  end
  
  # This version (note the '!') works with exceptions
  def self.find_by_uuid!(uuid)
    log_message = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(log_message) {'entered with uuid='+uuid}
    response = getCurb(url: @@url + '/functions/' + uuid, headers: JSON_HEADERS)
    GtkApi.logger.debug(log_message) {"response=#{response}"}
    case response[:status]
    when 200
      FunctionManagerService.new({uuid: response[:data][:uuid]})
    else
      raise FunctionNotFoundError.new 'Function with uuid='+uuid+' not found'
    end
  end

  def self.find(params)
    #find(url: @@url + '/functions', params: params, log_message: LOG_MESSAGE + "##{__method__}(#{params})")
    log_message = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(log_message) {"entered with params #{params}"}
    response = getCurb(url: @@url + '/functions', params: params)
    GtkApi.logger.debug(log_message) {"response=#{response}"}
    response
  end
  
  def load_instances(uuid)
    log_message = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(log_message) {'entered with uuid='+uuid}
    
    # TODO: this is not right... yet!
    instances = RecordManagerService.find_records_by_function_uuid(uuid)
    case instances[:status]
    when 200
      @instances = instances[:items]
    else
      @instances = nil
    end
  end
end

