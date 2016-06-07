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

class PackageManagerService
  
  attr_reader :url, :logger
  
  def initialize(url, logger)
    @url = url
    @logger = logger
  end
    
  def create(params)
    @logger.debug "PackageManagerService.create: params=#{params}"
    tmpfile = params[:package][:tempfile]
    uri = @url+'/packages'
    @logger.debug "PackageManagerService.create: uri="+uri
    response = RestClient.post(uri, params)
    @logger.debug "PackageManagerService.create: response.class=#{response.class}"
    @logger.debug "PackageManagerService.create: response=#{response}"
    JSON.parse response
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
    @logger.debug "PackageManagerService.get_log: url "+@url+'/admin/logs'
    RestClient.get(@url+'/admin/logs')      
  end
end
