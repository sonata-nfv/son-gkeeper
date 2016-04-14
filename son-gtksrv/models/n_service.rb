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

class NService
    
  def self.find(params)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params unless params.empty?
    pp "NService::find(#{params}): headers #{headers}"
    begin
      response = RestClient.get(GtkSrv.settings.catalogues['url']+'/network-services', headers)
      pp "NService#find(#{params}): #{response}"      
      JSON.parse response.body
    rescue => e
      e.to_json
    end
  end

  def self.find_by_uuid(uuid)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = uuid
    begin
      response = RestClient.get( GtkSrv.settings.catalogues['url']+"/network-services/#{uuid}", headers) 
      JSON.parse response.body
    rescue => e
      e.to_json
    end
  end

end