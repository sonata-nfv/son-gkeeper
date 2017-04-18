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
require './models/manager_service.rb'
require 'base64'

class UserNotCreatedError < StandardError; end
class UserNotAuthenticatedError < StandardError; end
class UserNotFoundError < StandardError; end
class UsersNotFoundError < StandardError; end
class UserNameAlreadyInUseError < StandardError; end

class User < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name
  USERS_URL = '/users/'
  
  attr_accessor :uuid, :username, :session, :secret
  
  # {"username" => "sampleuser", "enabled" => true, "totp" => false, "emailVerified" => false, "firstName" => "User", "lastName" => "Sample", "email" => "user.sample@email.com.br", "credentials" => [ {"type" => "password", "value" => "1234"} ], "requiredActions" => [], "federatedIdentities" => [], "attributes" => {"developer" => ["true"], "customer" => ["false"], "admin" => ["false"]}, "realmRoles" => [], "clientRoles" => {}, "groups" => ["developers"]}
  
  def self.config(url:)
    method = LOG_MESSAGE + __method__.to_s
    raise ArgumentError.new('UserManagerService can not be configured with nil or empty url') if (url.nil? || url.empty?)
    @@url = url
    GtkApi.logger.debug(method) {'entered with url='+url}
  end
  
  def initialize(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    raise ArgumentError.new('UserManagerService can not be instantiated without a user name') unless (params.key?(:username) && !params[:username].empty?)
    raise ArgumentError.new('UserManagerService can not be instantiated without a password') unless (params.key?(:password) && !params[:password].empty?)
    @username = params[:username]
    @secret = Base64.strict_encode64(params[:username]+':'+params[:password])
    @session = nil
    @uuid = params[:uuid]
  end

  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with #{params}"}

    saved_params = params.dup
    
    # Transform password
    password = params.delete(:password)
    params[:credentials] = [{type: 'password', value: password}]
    
    # Transform user type
    user_type = params.delete(:user_type)
    GtkApi.logger.debug(method) {"user type is #{user_type}"}
    params[:attributes] = {}
    # :attributes=>{:userType=>["developer"]}
    params[:attributes][:userType] = [user_type]
    params[:attributes][:certificate] = params.delete(:certificate) if params[:certificate]
    params[:attributes][:public_key] = params.delete(:public_key) if params[:public_key]
    GtkApi.logger.debug(method) {"params = #{params}"}
    
    # This doesn't work:
    # {"username":"test","email":"a@example.com","credentials":[{"type":"password","value":"123"}],"attributes":{"userType":["developer"]}}
    # This woks:
    # {"username":"user05","email":"test.jenkins@email.com","credentials":[{"type":"password","value":"1234"}],"attributes":{"userType": ["developer", "customer"]}}
    begin
      resp = postCurb(url: @@url+'/api/v1/register/user', body: params)
      case resp[:status]
      when 200..202
        user = resp[:items]
        GtkApi.logger.debug(method) {"user=#{user}"}
        saved_params[:uuid] = user[:userId] unless user.empty?
        User.new(saved_params)
        #  (){username: user[:username], password: user[:credentials][0][:value],
        #  lastName: user[:lastName], firstName: user[:firstName],
        #  email: user[:email], token: user[:token],
        #  user_type: user[:attributes].key(['true']) # returns the first one to be true
        #})
      when 409
        GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
        User.find_by_name params[:username]
      when 403
        GtkApi.logger.error(method) {"Why return 403?!?"} 
        raise UserNameAlreadyInUseError.new "Why return 403?!? with params #{params}"
      else
        GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
        raise UserNotCreatedError.new "User not created with params #{params}"
      end
    rescue  => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      raise UserNotCreatedError.new "User not created with params #{params}"
    end
  end

  def self.authenticated?(secret)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with secret=#{secret}"}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Base '+secret}
    begin
      resp = postCurb(url: @@url+'/api/v1/login/user', body: {}, headers: headers)
      if resp[:status] == 200
        token = resp[:items]
        GtkApi.logger.debug(method) {"token=#{token}"}
        {began_at: Time.now.utc, token: token}
      else
        GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
        raise UserNotAuthenticatedError.new "User not authenticated with params #{secret}"
      end
    rescue  => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      raise UserNotAuthenticatedError.new "User not authenticated with params #{secret}"
    end
  end

  def logout!
    session_lasted_for = Time.now.utc - @session[:began_at]
    @user_session = nil
    session_lasted_for
  end
  
  def authorized?(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    true
  end
  
  def self.valid?(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    true
  end
  
  def self.find_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    user = find(url: @@url + USERS_URL + uuid, log_message: LOG_MESSAGE + "##{__method__}(#{uuid})")
    user ? User.new(user['data']) : nil
  end

  def self.find_by_name(name)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with name #{name}"}
    #user=find(url: @@url + USERS_URL + name, log_message: LOG_MESSAGE + "##{__method__}(#{name})")
    #user ? User.new(user['data']) : nil
    name=='Unknown' ? User.new({username: 'Unknown', password: 'None'}) : nil
  end

  def self.find(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    params[:username]=='Unknown' && Base64.decode64(params[:secret]).split(':')[1]=='None' ? self.new_user(params) : self.no_users()
    #users = find(url: @@url + USERS_URL, params: params, log_message: LOG_MESSAGE + "##{__method__}(#{params})")
    #GtkApi.logger.debug(method) {"users=#{users}"}
    #case users[:status]
    #when 200
    #  {status: 200, count: users[:items][:data][:licences].count, items: users[:items][:data][:licences], message: "OK"}
    #when 400
    #when 404
    #  {status: 200, count: 0, items: [], message: "OK"}
    #else
    #  {status: users[:status], count: 0, items: [], message: "Error"}
    #end
  end
  
  def self.public_key
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    begin
      p_key = getCurb(url: @@url+'/api/v1/public-key', params: {}, headers: {})
      GtkApi.logger.debug(method) {"p_key=#{p_key}"}
      p_key
    rescue  => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      raise PublicKeyNotFoundError.new('No public key received from User Management micro-service')
    end
  end
  
  private 
  
  # these are temporary, waiting for the integration with the User Management
  def self.new_user(params)
    {status: 200, count: 1, items: [User.new(params)]}
  end
  
  def self.no_users()
    {status: 200, count: 0, items: []}
  end
end
