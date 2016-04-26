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
require 'json' 
require 'pp'
require 'addressable/uri'

class GtkSrv < Sinatra::Base

  get '/services/?' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkSrv: entered GET /services/#{uri.query}"
    
    services = NService.find(params)
    logger.debug "GtkSrv: GET /services: #{services}"
    if services
      logger.debug "GtkSrv: leaving GET /services/#{uri.query}"
      halt 200, services.to_json
    else
      logger.debug "GtkSrv: leaving GET /services/#{uri.query} with \"No service with params=#{uri.query} was found\""
      json_error 404, "No service with params=#{uri.query} was found"
    end
  end
  
  get '/admin/logs' do
    logger.debug "GtkSrv: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end  
end
