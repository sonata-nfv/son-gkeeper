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
require './models/manager_service.rb'

class PackageManagerService < ManagerService

  attr_reader :url, :logger
  
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def self.create(params)
    method = LOG_MESSAGE + ".create(#{params})"
    @@logger.debug(method) {'entered'}

    @@logger.debug(method) {"params=#{params}"}
    tmpfile = params[:package][:tempfile]
    uri = @@url+'/packages'
    @@logger.debug(method) {"uri="+uri}
    begin
      response = RestClient.post(uri, params)
      @@logger.debug(method) {"response.class=#{response.class}"}
      @@logger.debug(method) {"response=#{response}"}
      JSON.parse response
    rescue  => e #RestClient::Conflict
      @@logger.debug(method) {e.response}
      {error: 'Package is duplicated', package: e.response}
    end    
  end    

  def self.find_by_uuid(uuid)
    method = LOG_MESSAGE + ".find_by_uuid(#{uuid})"
    @@logger.debug(method) {'entered'}
    headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
    headers[:params] = uuid
    begin
      # Get the meta-data first
      response = RestClient.get(@@url+"/packages/#{uuid}", headers)
      filename = JSON.parse(response)['filepath']
      @@logger.debug(method) {"filename='"+filename+"'"}
      path = File.join('public','packages',uuid)
      FileUtils.mkdir_p path unless File.exists? path
      
      # Get the package it self
      package = RestClient.get(@@url+"/packages/#{uuid}/package")
      File.open(filename, 'wb') do |f|
        f.write package
      end
      filename
    rescue => e
      e.to_json
    end
  end
  
  def self.find(params)
    method = LOG_MESSAGE + ".find(#{params})"
    @@logger.debug(method) {'entered'}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params
    begin
      response = RestClient.get(@@url+'/packages', headers)
      @@logger.debug(method) {"response #{response}"}
      response
    rescue => e
      @@logger.debug(method) {e.response}
      nil
    end
  end
end
