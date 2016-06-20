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
require 'yaml'
require 'bunny'

class GtkVim < Sinatra::Base  

  # Gets the list o vims
  get '/vim/?' do
    original_body = request.body.read

    logger.info "GtkVim: GET /vim with params=#{params}"
    
    begin
      start_request={}
      
      query_request = VimsQuery.create(params)
      smresponse = settings.mqserver.publish( start_request.to_json, VimsQuery['id'])
      json_request = json(VimsQuery, { root: false })
      logger.info 'GtkVim: returning GET /vim with request='+json_request
      halt 201, json_request
      
    rescue Exception => e
      logger.debug(e.message)
	    logger.debug(e.backtrace.inspect)
	    halt 500, 'Internal server error'
    end
  end
 
end
