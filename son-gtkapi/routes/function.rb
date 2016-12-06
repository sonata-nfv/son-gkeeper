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
require 'addressable/uri'

class GtkApi < Sinatra::Base
  
  # GET many functions
  get '/functions/?' do
    log_message = MODULE+' GET /functions'
    logger.debug(log_message) {'entered'}
    
    uri = Addressable::URI.new
    uri.query_values = params
    
    params[:offset] ||= DEFAULT_OFFSET 
    params[:limit] ||= DEFAULT_LIMIT
    logger.debug(log_message) {"params=#{uri.query}"}
     
    functions = settings.function_management.find_functions(params)
    if functions
      logger.debug(log_message) {"leaving with #{functions}"}
      halt 200, functions.to_json if functions
    else
      error_message = "No function with params #{uri.query} was found"
      logger.debug(log_message) {'leaving with "'+error_message+'"'}
      json_error 404, error_message
    end  
  end
  
  # GET function by uuid
  get '/functions/:uuid' do
    log_message = MODULE+' GET /functions/:uuid'
    
    unless params[:uuid].nil?
      logger.info "GtkApiss: entered GET \"/functions/#{params[:uuid]}\""
      function = settings.function_management.find_functions_by_uuid(params[:uuid])
      if function 
        logger.info "GtkApi: in GET /functions/#{params[:uuid]}, found function #{function}"
        response = function
        logger.info "GtkApi: leaving GET /functions/#{params[:uuid]} with response="+response
        halt 200, response
      else
        logger.error "GtkApi: leaving GET \"/functions/#{params[:uuid]}\" with \"No functions with UUID=#{params[:uuid]} was found\""
        json_error 404, "No function with UUID=#{params[:uuid]} was found"
      end
    end
    logger.error "GtkApi: leaving GET \"/functions/#{params[:uuid]}\" with \"No function UUID specified\""
    json_error 400, 'No function UUID specified'
  end
  
  get '/admin/functions/logs' do
    logger.debug('GtkApi GET /admin/functions/logs') {'entered'}
    headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    log = settings.function_management.get_log
    halt 200, log #.to_s
  end
end
