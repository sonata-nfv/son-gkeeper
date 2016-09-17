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
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    #headers[:params] = uuid
    begin
      response = RestClient.get(@url+"/#{uuid}", headers) 
      JSON.parse response.body
    rescue => e
      @logger.error format_error(e.backtrace)
      e.to_json
    end
  end
  
  def find(params)
    method = 'Catalogue.find: '
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params unless params.empty?
    @logger.debug(method) {"params=#{params}, headers=#{headers}"}
    begin
      response = RestClient.get(@url, headers)
      @logger.debug(method) {"response was #{response}"}     
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