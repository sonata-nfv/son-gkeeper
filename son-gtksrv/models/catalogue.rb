## SONATA - Gatekeeper
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
      response = RestClient.get(@url+"/#{uuid}", JSON_HEADERS) 
      JSON.parse response.body
    rescue => e
      @logger.error format_error(e.backtrace)
      e.to_json
    end
  end
  
  def find(params)
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    @logger.debug "Catalogue::find(#{params}): headers #{headers}"
    begin
      response = RestClient.get(@url, headers)
      @logger.debug "Catalogue#find(#{params}): #{response}"      
      JSON.parse response.body
    rescue => e
      @logger.error format_error(e.backtrace)
      e.to_json
    end
  end
  
  def update
  end
  
  def delete
  end
  
  private
  
  def format_error(backtrace)
    first_line = backtrace[0].split(":")
    "In "+first_line[0].split("/").last+", "+first_line.last+": "+first_line[1]
  end
  
end