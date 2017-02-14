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
require 'tempfile'
require 'json'
require 'pp'

class Catalogue
  
  attr_accessor :url
  
  JSON_HEADERS = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
  
  def initialize(url, logger)
    @url = url
    @logger = logger
  end
    
  def create(descriptor)
    @logger.debug "Catalogue.create("+descriptor.to_s+")"
    begin
      response = RestClient.post( @url, descriptor.to_json, content_type: :json, accept: :json)     
      object = JSON.parse response
      @logger.debug "Catalogue.create: object=#{object}"
      object
    rescue => e
      @logger.error format_error(e.backtrace)
      nil
    end
  end
  
  def find_by_uuid(uuid)
    @logger.debug "Catalogue.find_by_uuid(#{uuid})"
    begin
      _response = RestClient.get(@url+"/#{uuid}", JSON_HEADERS) 
      @logger.debug "Catalogue.find_by_uuid(#{uuid}): response=#{_response}"
      parsed_response = JSON.parse _response #.body
      @logger.debug "Catalogue.find_by_uuid(#{uuid}): parsed_response=#{parsed_response}"
      parsed_response
    rescue => e
      @logger.error format_error(e.backtrace)
      e.to_json
    end
  end
  
  def find(params)
    log_message="Catalogue.find"
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @logger.debug(log_message) {"entered, with params #{params} and headers #{headers}"}
    result={}
    begin
      # First fetch all records without any restriction
      unrestricted = RestClient.get(@url, JSON_HEADERS)
      @logger.debug(log_message) {"unrestricted #{unrestricted}"}
      
      json_unrestricted = JSON.parse unrestricted.body
      @logger.debug(log_message) {"json_unrestricted #{json_unrestricted}"}

      if json_unrestricted.empty?
        @logger.debug(log_message) {"unrestricted has no records"}
        result = {count: 0, items: {}}
      elsif json_unrestricted.count == 1
        # If there's only one, that's it
        @logger.debug(log_message) {"unrestricted has only one record"}
        result = {count: 1, items: json_unrestricted[0]}
      else # Should have more than one record
        @logger.debug(log_message) {"unrestricted has more than one record"}
        result[:count] = json_unrestricted.count
        
        # Now fetch the real result
        records = RestClient.get(@url, headers)
        @logger.debug(log_message) {"records #{records}"}
        result[:items] = JSON.parse records.body
      end
      result
    rescue => e
      @logger.error(log_message) {format_error(e.backtrace)}
      []
    end
  end
  
  def update(uuid)
    @logger.debug "Catalogue.update(#{uuid})"
  end
  
  def delete(uuid)
    @logger.debug "Catalogue.delete(#{uuid})"
  end
  
  private
  
  def format_error(backtrace)
    first_line = backtrace[0].split(":")
    "In "+first_line[0].split("/").last+", "+first_line.last+": "+first_line[1]
  end
  
end