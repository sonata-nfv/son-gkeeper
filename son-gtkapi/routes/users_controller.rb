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
  helpers GtkApiHelper
  
  namespace '/api/v2' do
    options '/users/?' do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST,PUT'      
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
      halt 200
    end
    
    # GET many users
    get '/users/?' do
      log_message = MODULE+' GET /api/v2/users'
    
      logger.debug(log_message) {'entered with '+query_string}
    
      @offset ||= params['offset'] ||= DEFAULT_OFFSET
      @limit ||= params['limit'] ||= DEFAULT_LIMIT
      logger.debug(log_message) {"offset=#{@offset}, limit=#{@limit}"}
      logger.debug(log_message) {"params=#{params}"}
    
      users = User.find(params)
      logger.debug(log_message) {"Found users #{users}"}
      case users[:status]
      when 200
        logger.debug(log_message) {"links: request_url=#{request_url}, limit=#{@limit}, offset=#{@offset}, total=#{users[:count]}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: users[:count].to_i)
        logger.debug(log_message) {"links: #{links}"}
        headers 'Link'=> links, 'Record-Count'=> users[:count].to_s
        status 200
        halt users[:items].to_json
      else
        message = "No users with #{params} were found"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
  
    # GET a specific user
    get 'users/:name/?' do
      log_message = MODULE+' GET /api/v2/services/:name'
      logger.debug(log_message) {"entered with #{params}"}
    
      if valid?(params[:name])
        # TODO: mind that, besides the URL-based uuid we might as well pass other params, like fields we want to show
        #params.delete :uuid
        user = User.find_by_name(params[:name])
        if user[:count] && !user[:items].empty?
          logger.debug(log_message) {"leaving with #{user}"}
          halt 200, user.to_json
        else
          logger.debug(log_message) {"leaving with message 'User #{params[:name]} not found'"}
          json_error 404, "User #{params[:name]} not found"
        end
      else
        message = "User #{params[:name]} not valid"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
  

    #get '/admin/users/logs/?' do
    #  log_message = 'GtkApi::GET /admin/services/logs'
    #  logger.debug(log_message) {'entered'}
    #  headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    #  log = ServiceManagerService.get_log(url:ServiceManagerService.class_variable_get(:@@url)+'/admin/logs', log_message:log_message)
    #  logger.debug(log_message) {'leaving with log='+log}
    #  halt 200, log
    #end
  end
end
