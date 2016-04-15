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

  get '/requests/:uuid/?' do
    logger.debug "GtkPkg: entered GET \"/requests/#{params[:uuid]}\""
    requests = Request.find(params[:uuid])
    halt 200, requests.to_json
  end

  post '/requests/?' do
    logger.info "GtkPkg: entered POST /requests"
    request = Request.create() # No parameter passed for now
    
    halt 200, request.to_json if request.save
    json_error 400, 'Not possible to save the request'
  end
end
