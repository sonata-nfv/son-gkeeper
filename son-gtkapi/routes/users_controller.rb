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
  
  namespace '/api/v2/users' do
    options '/?' do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST,PUT'      
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
      halt 200
    end
    
    # POST new users
    post '/?' do
      log_message = 'GtkApi::POST /api/v2/users/?'
      params = JSON.parse(request.body.read, symbolize_names: true)
      
      logger.info(log_message) {"entered with params=#{params}"}
      
      # {"username" => "sampleuser", "firstName" => "User", "lastName" => "Sample", "email" => "user.sample@email.com.br", "password" => "1234", "user_type" => "developer"|"customer"|"admin"}
      
      json_error(400, 'User name is missing', log_message) unless valid_param?(params: params, sym: :username)
      json_error(400, 'User password is missing', log_message) unless valid_param?(params: params, sym: :password)
      json_error(400, 'User email is missing', log_message) unless valid_param?(params: params, sym: :email)
      json_error(400, 'User type is missing', log_message) unless valid_param?(params: params, sym: :user_type)
    
      begin
        user = User.create(params)
        logger.info(log_message) {"leaving with user name #{user.username}"}
        headers 'Location'=> User.class_variable_get(:@@url)+"/api/v2/users/#{user.uuid}", 'Content-Type'=> 'application/json'
        halt 201, { username: user.username, uuid: user.uuid}.to_json
      rescue UserNameAlreadyInUseError
        json_error 409, "User name #{params[:username]} already in use", log_message
      rescue UserNotCreatedError
        json_error 400, "Error creating user #{params}", log_message
      end
    end
    
    # GET many users
    get '/?' do
      log_message = 'GtkApi:: GET /api/v2/users'
    
      logger.debug(log_message) {'entered with '+query_string}
    
      @offset ||= params['offset'] ||= DEFAULT_OFFSET
      @limit ||= params['limit'] ||= DEFAULT_LIMIT
      logger.debug(log_message) {"offset=#{@offset}, limit=#{@limit}"}
      logger.debug(log_message) {"params=#{params}"}
    
      begin
        users = User.find(params)
        logger.debug(log_message) {"Found users #{users}"}
        logger.debug(log_message) {"links: request_url=#{request_url}, limit=#{@limit}, offset=#{@offset}, total=#{users.count}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: users.count)
        logger.debug(log_message) {"links: #{links}"}
        headers 'Link'=> links, 'Record-Count'=> users.count.to_s
        returned_users = []
        users.each do |user|
          returned_users << user.to_h
        end
        content_type :json
        halt 200, returned_users.to_json
      rescue UsersNotFoundError
        logger.debug(log_message) {"Users not found"}
        halt 200, '[]'
      end
    end
  
    # GET a specific user
    get '/:uuid/?' do
      log_message = 'GtkApi:: GET /api/v2/services/:uuid'
      logger.debug(log_message) {"entered with #{params}"}
    
      if valid?(params[:uuid])
        # TODO: mind that, besides the URL-based uuid we might as well pass other params, like fields we want to show
        #params.delete :uuid
        begin
          user = User.find_by_uuid(params[:uuid])
          logger.debug(log_message) {"leaving with #{user}"}
          content_type :json
          halt 200, user.to_h.to_json
        rescue UserNotFoundError
          json_error 404, "User #{params[:uuid]} not found", log_message
        end
      else
        json_error 404, "User #{params[:uuid]} not valid", log_message
      end
    end
  
    # GET .../api/v2/micro-services/users/public-key: To get the UM's public-key:
    get '/public-key/?' do
      log_message = 'GtkApi:: GET /api/v2/users/public-key'
      logger.debug(log_message) {"entered with #{params}"}
    
      begin
        pk = User.public_key
        logger.debug(log_message) {"leaving with #{pk}"}
        halt 200, pk.to_json
      rescue PublicKeyNotFoundError
        json_error 404, "No public key for the User Management micro-service was found", log_message
      end
    end
  end

  get '/api/v2/admin/users/logs/?' do
    log_message = 'GtkApi::GET /admin/users/logs'
    logger.debug(log_message) {'entered'}
    headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
    log = User.get_log(url:User.class_variable_get(:@@url)+'/admin/logs', log_message:log_message)
    logger.debug(log_message) {"leaving with log=#{log}"}
    halt 200, log
  end
  
  private
  
  def valid_param?(params:, sym:)
    log_message = 'GtkApi::'+__method__.to_s
    logger.debug(log_message) {"params=#{params}, sym=#{sym}"}
    params.key?(sym) && !params[sym].empty?
  end
end
