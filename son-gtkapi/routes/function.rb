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
require 'sinatra/namespace'
class GtkApi < Sinatra::Base

  register Sinatra::Namespace
  
  namespace '/api/v2/functions' do
    # GET many functions
    get '/?' do
      log_message = 'GtkApi::GET /api/v2/functions/?'
      logger.debug(log_message) {'entered with '+query_string}
    
      @offset ||= params[:offset] ||= DEFAULT_OFFSET 
      @limit ||= params[:limit] ||= DEFAULT_LIMIT
      logger.debug(log_message) {"params=#{params}"}
     
      functions = FunctionManagerService.find_functions(params)
      if functions
        logger.debug(log_message) {"leaving with #{functions}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: functions.size)
        [200, {'Link' => links}, functions.to_json]
      else
        error_message = "No function with params #{params} was found"
        logger.debug(log_message) {'leaving with "'+error_message+'"'}
        json_error 404, error_message
      end  
    end
  
    # GET function by uuid
    get '/:uuid/?' do
      log_message = 'GtkApi::GET /api/v2/functions/:uuid/?'
      logger.debug(log_message) {"entered with #{params[:uuid]}"}
    
      if valid?(params[:uuid])
        function = FunctionManagerService.find_function_by_uuid(params[:uuid])
        if function
          logger.debug(log_message) {"leaving with #{function}"}
          halt 200, function.to_json
        else
          logger.debug(log_message) {"leaving with message 'Service #{params[:uuid]} not found'"}
          json_error 404, "Function #{params[:uuid]} not found"
        end
      else
        message = "Function #{params[:uuid]} not valid"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
  end
  
  namespace '/api/v2/admin/functions' do
    get '/logs/?' do
      log_message = 'GtkApi::GET /admin/functions/logs'
      logger.debug(log_message) {'entered'}
      url = FunctionManagerService.class_variable_get(:@@url)+'/admin/logs'
      log = FunctionManagerService.get_log(url: url, log_message:log_message)
      logger.debug(log_message) {'leaving with log='+log}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      halt 200, log
    end
  end
end
