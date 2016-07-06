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
require 'uri'
require 'net/http'
require 'rest-client'

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

  def create_zip(zip)
    #url = URI("http://api.int.sonata-nfv.eu:4002/catalogues/son-packages")
    url = URI(@url)
    http = Net::HTTP.new(url.host, url.port)
    data = File.read('/home/tchalas/Documents/Sonata/sonata_example.son')  #File.read("/usr/test.amr")
    request = Net::HTTP::Post.new(url)
    request.body = data
    # These fields are mandatory
    request["content-type"] = 'application/zip'
    request["content-disposition"] = 'attachment; filename=<filename.son>'
    response = http.request(request)
    puts response.read_body
    # Response should return code 201, and ID of the stored son-package
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
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params unless params.empty?
    @logger.debug "Catalogue.find #{params} (with headers #{headers})"
    begin
      response = RestClient.get(@url, headers)
      @logger.debug "Catalogue.find: response was #{response}"      
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