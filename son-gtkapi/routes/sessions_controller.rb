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
    # AKA login
    post '/sessions/?' do
      log_message = 'GtkApi::POST /sessions/?'
      body = request.body.read
      logger.debug(log_message) {"body=#{body}"}      
      
      json_error(400, 'Unprocessable entity: missing session parameters', log_message) unless body
      
      # TODO: need to decode from base64 here
      params = JSON.parse(body, symbolize_names: true)
      logger.debug(log_message) {"entered with params=#{params}"}
      json_error(400, 'Unprocessable entity: missing user name', log_message) if (params[:name].nil? || params[:name].empty?)
      json_error(400, 'Unprocessable entity: missing user password', log_message) if (params[:password].nil? || params[:password].empty?)

      user = User.find_by_name(params[:name])
      if user
        logger.debug(log_message) {"user=#{user.inspect}"}
        session = user.authenticate!({uuid: user.uuid, password: params[:password]})
        if session
          logger.debug(log_message) {"leaving with session #{session.inspect}"}
          halt 200, 'User '+params[:name]+' authenticated'
        else
          json_error 401, 'Unauthorized: user '+params[:name]+' not authenticated', log_message
        end
      else
        json_error 404, 'User '+params[:name]+' not found', log_message
      end
    end

    # AKA logout
    delete '/sessions/:user_name/?' do
      log_message = 'GtkApi::DELETE /sessions/?'
      logger.debug(log_message) {'entered with user_name='+params[:user_name]}      
      json_error(400, 'Unprocessable entity: missing user name', log_message) if (params[:user_name].nil? || params[:user_name].empty?)
      user = User.find_by_name(params[:user_name])
      if user
        logger.debug(log_message) {"user=#{user.inspect}"}
        session_duration = user.logout!
        halt 200, "{'session_lasted_for':'"+session_duration.to_s+"'}"
      else
        json_error 404, 'User '+params[:user_name]+' not found', log_message
      end
    end
  end
end
