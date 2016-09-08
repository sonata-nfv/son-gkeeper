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

class PackageManagerService
  
  attr_reader :url, :logger
  
  def initialize(url, logger)
    @url = url
    @logger = logger
  end
    
  def create(params)
    log_message = 'PackageManagerService.create'
    @logger.debug(log_message) {"params=#{params}"}
    tmpfile = params[:package][:tempfile]
    uri = @url+'/packages'
    @logger.debug(log_message) {"uri="+uri}
    begin
      response = RestClient.post(uri, params)
      @logger.debug(log_message) {"response.class=#{response.class}"}
      @logger.debug(log_message) {"response=#{response}"}
      JSON.parse response
    rescue  => e #RestClient::Conflict
      @logger.debug(log_message) {e.response}
      {error: 'Package is duplicated', package: e.response}
    end
    #RestClient.get('http://my-rest-service.com/resource'){ |response, request, result, &block|
    #  case response.code
    #  when 200
    #    p "It worked !"
    #    response
    #  when 423
    #    raise SomeCustomExceptionIfYouWant
    #  else
    #    response.return!(request, result, &block)
    #  end
    #}
    
  end    

  def find_by_uuid(uuid)
    headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
    headers[:params] = uuid
    begin
      # Get the meta-data first
      response = RestClient.get(@url+"/packages/#{uuid}", headers)
      filename = JSON.parse(response)['filepath']
      @logger.debug "PackageManagerService.find_by_uuid(#{uuid}): filename=\""+filename+"\""
      path = File.join('public','packages',uuid)
      FileUtils.mkdir_p path unless File.exists? path
      
      # Get the package it self
      package = RestClient.get(@url+"/packages/#{uuid}/package")
      File.open(filename, 'wb') do |f|
        f.write package
      end
      filename
    rescue => e
      e.to_json
    end
  end
  
  def find(params)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params
    begin
      response = RestClient.get(@url+'/packages', headers)
      @logger.debug "PackageManagerService.find: response #{response}"
      response
    rescue => e
      e.to_json 
    end
  end
  
  def get_log
    method = "GtkApi::PackageManagerService.get_log: "
    @logger.debug(method) {'entered'}
    full_url = @url+'/admin/logs'
    @logger.debug(method) {'url=' + full_url}
    RestClient.get(full_url)      
  end
end
