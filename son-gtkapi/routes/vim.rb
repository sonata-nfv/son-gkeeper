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
require 'addressable/uri'

class GtkApi < Sinatra::Base
  
  before do
     if request.request_method == 'OPTIONS'
       response.headers['Access-Control-Allow-Origin'] = '*'
       response.headers['Access-Control-Allow-Methods'] = 'POST'      
       response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
       halt 200
     end
   end
  
  # POST a request
  post '/vim/?' do
    params = JSON.parse(request.body.read)
    unless params.nil?
      logger.debug "GtkApi: POST / with params=#{params}"
      new_request = settings.vim_management.create_vim(params)
      if new_request
        logger.debug "GtkApi: POST /vim: new_request =#{new_request}"
        halt 201, new_request.to_json
      else
        logger.debug "GtkApi: leaving POST /vim with 'No vim creation request was created'"
        json_error 400, 'No vim create_request was created'
      end
    end
    logger.debug "GtkApi: leaving POST /vim with 'No request id specified'"
    json_error 400, 'No params specified for the create request'
  end

  # GET many vims
  get '/vim/?' do
    uri = Addressable::URI.new
    #params['offset'] ||= DEFAULT_OFFSET 
    #params['limit'] ||= DEFAULT_LIMIT
    uri.query_values = params
    logger.info "GtkApi: entered GET /vim?#{uri.query}"
    vims = settings.vim_management.find_vims(params)
    logger.debug "GtkApi: GET /vims?#{uri.query} gave #{vims}"
    if vims 
      logger.info "GtkApi: leaving GET /vim?#{uri.query} with #{vims}"
      halt 200, vims.to_json
    else
      logger.info "GtkApi: leaving GET /vim?#{uri.query} with 'No get vims request were created'"
      json_error 400, 'No get list of vims request was created'
    end
  end
  
  # GET one specific request
  get '/vim_request/:uuid/?' do
    unless params[:uuid].nil?
      logger.debug "GtkApi: GET /vim_request/#{params[:uuid]}"
      json_error 400, 'Invalid request UUID' unless valid? params[:uuid]
      
      request = settings.vim_management.find_vim_request_by_uuid(params['uuid'])
      json_error 404, "The vim_request UUID #{params[:uuid]} does not exist" unless request

      logger.debug "GtkApi: leaving GET /vim_request/#{params[:uuid]}\" with request #{request}"
      halt 200, request.to_json
    end
    logger.debug "GtkApi: leaving GET /vim_request/#{params[:uuid]} with 'No vim_request UUID specified'"
    json_error 400, 'No vim_request UUID specified'
  end
  
end
