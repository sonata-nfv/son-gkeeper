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

class FunctionManagerService < ManagerService
    
  # We're not yet using this: it allows for multiple implementations, such as Fakes (for testing)
  attr_reader :url, :logger
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def initialize(url, logger)
    method = LOG_MESSAGE + ".new(url=#{url}, logger=#{logger})"
    super
    @logger.debug(method) {'entered'}
  end

  def find_functions_by_uuid(uuid)
    method = LOG_MESSAGE + ".find_functions_by_uuid(#{uuid})"
    @logger.debug(method) {'entered'}
    begin
      response = getCurb( url: @url + '/functions/'+uuid, headers: JSON_HEADERS)
      @logger.debug(method) {"response=#{response.inspect}"}
      case response.status
        when 200
          @logger.debug(method) {'found function ' + response.body}
          JSON.parse response.body
        when 404
          @logger.error(method) {"Function with UUID=#{uuid} was not found"}
          nil
        else
          @logger.error(method) {"Strange error (#{response.status}) while looking for function with UUID=#{uuid}"}
          nil
      end
    rescue => e
      @logger.error(method) {"e=#{e.backtrace}"}
      nil 
    end
  end
  
  def find_functions(params)
    method = LOG_MESSAGE + ".find_functions(#{params})"
    @logger.debug(method) {'entered'}
    begin
      response = getCurb(url: @url + '/functions', params: params, headers: JSON_HEADERS) 
      @logger.debug(method) {"response=#{response.inspect}"}
      case response.status
        when 200
          @logger.debug(method) {'found function(s) ' + response.body}
          JSON.parse response.body
        when 404
          @logger.error(method) {"Function with params=#{params} were not found"}
          []
        else
          @logger.error(method) {"Strange error (#{response.status}) while looking for function with params=#{params}"}
          nil
      end
    rescue => e
      @logger.error(method) {"e=#{e.backtrace}"}
      nil 
    end
  end
end
