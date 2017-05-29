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
require 'date'

class UserNotCreatedError < StandardError; end
class UserNotAuthenticatedError < StandardError; end
class UserNotFoundError < StandardError; end
class UsersNotFoundError < StandardError; end
class UserNotUpdatedError < StandardError; end
class UserNameAlreadyInUseError < StandardError; end
class UserNotLoggedOutError < StandardError; end
class UserTokenNotActiveError < StandardError; end
class UserPublicKeyNotUpdatedError < StandardError; end

class User < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name
  
  attr_accessor :uuid, :username, :session, :secret, :created_at, :user_type, :email, :last_name, :first_name, :public_key, :certificate
  
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
    #raise ArgumentError.new('UserManagerService can not be instantiated without a password') unless (params.key?(:password) && !params[:password].empty?)
    @username = params[:username]
    @secret = Base64.strict_encode64(params[:username]+':'+params[:password]) if params[:password]
    @session = nil
    @uuid = params[:uuid]
    @created_at = params[:created_at]
    @user_type = params[:user_type]
    @email = params[:email]
    @last_name = params[:last_name] if params[:last_name]
    @first_name = params[:first_name] if params[:first_name]
    @public_key = params[:public_key] if params[:public_key]
    @certificate = params[:certificate] if params[:certificate]
  end

  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with #{params}"}

    saved_params = params.dup
    
    params[:firstName] = params.delete(:first_name) if params[:first_name]
    params[:lastName] = params.delete(:last_name) if params[:last_name]
    
    # Transform password
    params[:credentials] = [{type: 'password', value: params.delete(:password)}]
    
    # Transform user type
    params[:attributes] = {}
    params[:attributes][:userType] = [params.delete(:user_type)]
    params[:attributes][:phone_number] = [params.delete(:phone_number)] if params[:phone_number]
    params[:attributes][:certificate] = [params.delete(:certificate)] if params[:certificate]
    params[:attributes][:public_key] = [params.delete(:public_key)] if params[:public_key]
    GtkApi.logger.debug(method) {"params = #{params}"}
    
    begin
      resp = postCurb(url: @@url+'/api/v1/register/user', body: params)
      case resp[:status]
      when 200..202
        user = resp[:items]
        raise UserNotCreatedError.new "User not created with params #{params}" unless user.key? :userId
        GtkApi.logger.debug(method) {"user=#{user}"}
        saved_params[:uuid] = user[:userId] unless user.empty?
        User.new(saved_params)
      when 409
        GtkApi.logger.error(method) {"Status 409"} 
        raise UserNameAlreadyInUseError.new "User name #{params[:username]} already in use"
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
    raise ArgumentError.new 'Authentication needs the user secret' if (secret.nil? || secret.empty?)
    
    GtkApi.logger.debug(method) {"entered with secret=#{secret}"}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Basic '+secret}
    begin
      resp = postCurb(url: @@url+'/api/v1/login/user', body: {}, headers: headers)
      case resp[:status]
      when 200
        token = resp[:items]
        GtkApi.logger.debug(method) {"token=#{token}"}
        {began_at: Time.now.utc, token: token}
      when 401
        GtkApi.logger.error(method) {"Status 401"} 
        raise UserNotAuthenticatedError.new "User not authenticated with params #{secret}"
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

  def self.logout!(token)
    method = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new 'Logging out requires the login token' if (token.nil? || token.empty?)
    GtkApi.logger.debug(method) {"entered"}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Bearer '+token}

    resp = postCurb(url: @@url+'/api/v1/logout', body: {}, headers: headers)
    case resp[:status]
    when 204
      GtkApi.logger.debug(method) {"User logged out"}
      {lasted_for: Time.now.utc}
    when 401
      GtkApi.logger.error(method) {"Status 401: token not active"} 
      raise UserTokenNotActiveError.new "User token was not active"
    else
      GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
      raise UserNotLoggedOutError.new "User not logged out with the given token"
    end
  end
  
  def self.authorized?(token:, params:)
    method = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new __method__.to_s+' requires the login token' if token.to_s.empty?
    raise ArgumentError.new __method__.to_s+' requires a path and a method to be authorized' if (params.to_s.empty? || !params.key?(:method) || !params.key?(:path))
    GtkApi.logger.debug(method) {"entered with token #{token} and params #{params}"}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Bearer '+token}

    resp = postCurb(url: @@url+'/api/v1/userinfo', body: params, headers: headers)
    # {:sub=>"fe53ac4f-052a-4a41-b7cd-914d4c64c2f8", :name=>"", :preferred_username=>"jbonnet", :email=>"jbonnet@alticelabs.com"}
    case resp[:status]
    when 200
      GtkApi.logger.debug(method) {"User authorized to #{params}"}
      true
    when 401
      GtkApi.logger.error(method) {"Status 401: User not authorized to #{params}"} 
      false
    else
      GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
      false
    end
  end
  
=begin
      The UM is expecting a PUT /api/v1/signatures/:username with a body like {"public_key":"..."}.
      HTTP method: PUT
      Authentication header includes the user's Access Token
      Parameter: username
      Body: JSON object that includes public_key field (required) and certificate field (optional). Sample:
      {"public_key": "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArVFiBHBiLPFRGrMobAxcK98SJRKKXJOkA66NL0UEgR7g8hOjVySchYUvtGAU5wi2ZCjmPGDT0hrJd1WEBplv0kT7YrIgdRGXGH73OJFjH8c7iX+XBwk0sH1K+KMUbszSbWFCKAlyHhYa8vz95RyzmzoMJZW6TeadlhRLuVw52RECaK9eIJu311oFA8os3z8J65olLexT0vF+B9Oqtn1gVJUfC0w984PXwMoGzSOVCbb5jD0/blAXonMS8PU+JFSGF4trTwRcmjw349NDEifUQamdHE8pynuxSpAuMN2WAPAlJpjnw/fHUxQFgRNGki6vHmegnQ6qmcbuorVW3oXkMwIDAQAB", "certificate": "optional"}
=end
  def update_public_key(token)
    method = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new __method__.to_s+' requires the login token' if token.to_s.empty?
    GtkApi.logger.debug(method) {"entered"}
    
    body={public_key: @public_key, certificate: @certificate}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Bearer '+token}
    resp = putCurb(url: @@url+'/api/v1/signatures/'+@username, body: params, headers: headers)
    case resp[:status]
    when 200 # signature is successfully updated
      GtkApi.logger.debug(method) {"User public-key updated"}
      self
    when 400 # Provided username does not match with Access Token, No username specified or Developer public key not provided
      GtkApi.logger.debug(method) {'Username '+@username+' does not match with token'}
      raise UserTokenNotActiveError.new 'Username '+@username+' does not match with token'
    when 401 # Token is not valid
      GtkApi.logger.debug(method) {'Username '+@username+' provided a token that is not valid'}
      raise UserTokenNotActiveError.new 'Username '+@username+' provided a token that is not valid'
    when 404 # Username is not found
      GtkApi.logger.debug(method) {'Username '+@username+' was not found'}
      raise UserNotFoundError.new 'Username '+@username+' was not found'
    else
      GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
      raise UserPublicKeyNotUpdatedError.new 'User public-key not updated'
    end
    
  end
  
  def self.valid?(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    true
  end
  
  def self.find_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with uuid #{uuid}"}
    begin
      response = getCurb(url:@@url + '/api/v1/users?id=' + uuid, headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"Got response: #{response}"}
      case response[:status]
      when 200
        user = response[:items].first
        unless user.empty?
          User.new( User.import(user))
        else
          raise UserNotFoundError.new "User with uuid #{uuid} was not found"
        end
      when 404
        raise UserNotFoundError.new 'User with uuid '+uuid+' was not found'
      else
        raise UserNotFoundError.new 'User with uuid '+uuid+' was not found'
      end
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  def self.find_by_name(name)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with name #{name}"}

    begin
      response = getCurb(url:@@url + '/api/v1/users?username=' + name, headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"Got response: #{response}"}
      case response[:status]
      when 200
        if response[:items].empty? || (user = response[:items].first).empty?
          raise UserNotFoundError.new "User with name #{name} was not found"
        end
        User.new( User.import(user))
      when 404
        raise UserNotFoundError.new "User with name #{name} was not found (code 404)"
      else
        raise UserNotFoundError.new 'User named '+name+' was not found'
      end
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
  def self.find(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}

    begin
      response = getCurb(url:@@url + '/api/v1/users', headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"Got response: #{response}"}
      case response[:status]
      when 200
        GtkApi.logger.debug(method) {'response[:items].empty? '+(response[:items].empty? ? 'yes' : 'no')}
        raise UsersNotFoundError.new "No users with params #{params} were found" if response[:items].empty?
        retrieved_users = []
        response[:items].each do |user|
          retrieved_users << User.new( User.import(user))
        end
        retrieved_users
      when 404
        raise UsersNotFoundError.new "Users with params #{params} were not found (code 404)"
      else 
        raise UsersNotFoundError.new "Users with params #{params} were not found(code #{response[:code]})"
      end
    rescue StandardError => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      []
    end
  end
  
  def self.find_username_by_token(token)
    # [23/05/2017, 09:33:28] Daniel Guija: url = URI("http://<address>:<port>/api/v1/userinfo")
    #  request["authorization"] = 'Bearer eyJhbGciOiJSkxX0NpUUhmTm9nIn0...'
    # [23/05/2017, 09:33:46] Daniel Guija: the response is:
    #  {"sub":"8031545e-d4da-4086-8cb2-a417f3460de2","name":"myName myLastName","preferred_username":"tester01","given_name":"myName","family_name":"myLastName","email":"myname.company@email.com"}
    # [23/05/2017, 09:34:08] Daniel Guija: just parse response['preferred_username'] to get the username

    method = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new __method__.to_s+' requires the login token' if (token.nil? || token.empty?)
    GtkApi.logger.debug(method) {"entered"}
    headers = {'Content-type'=>'application/json', 'Accept'=> 'application/json', 'Authorization'=>'Bearer '+token}

    resp = postCurb(url: @@url+'/api/v1/userinfo', body: {}, headers: headers)
    case resp[:status]
    when 200
      GtkApi.logger.debug(method) {"resp[:items]=#{resp[:items]}"}
      resp[:items][:preferred_username]
    when 401
      GtkApi.logger.error(method) {"Status 401: token not active"} 
      raise UserTokenNotActiveError.new "User token was not active"
    else
      GtkApi.logger.error(method) {"Status #{resp[:status]}"} 
      raise UserNotLoggedOutError.new "User not found with the given token"
    end  
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

  def update
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
  end
  
  def to_h
    h={}
    h[:username]= @username
    h[:uuid]=@uuid
    h[:created_at]=@created_at
    h[:user_type]=@user_type
    h[:email]=@email
    h[:last_name]=@last_name
    h[:first_name]=@first_name
    # :session, :secret
    h
  end
  
  def to_json
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered"}
    
    user = {}
    user[:username] = @username
    user[:uuid] = @uuid
    user[:created_at] = @created_at
    user[:user_type] = @user_type
    user[:email] = @email
    user[:last_name] = @last_name
    user[:first_name] = @first_name
    user[:public_key] = @public_key
    user[:certificate] = @certificate
    user
  end
  
  private 
  
  def self.import(original_user)
    # [{"id":"d6ec8201-3a9e-4cd3-a766-1ec93529c9d2","createdTimestamp":1493025941990,"username":"test5","enabled":true,"totp":false,"emailVerified":false,"firstName":"firstName","lastName":"lastName","email":"mail4@mail.com","attributes":{"phone_number":["654654654"],"userType":["customer"]},"disableableCredentialTypes":["password"],"requiredActions":[]}]
    user = {}
    user[:uuid] = original_user[:id]
    if original_user.key? :createdTimestamp
      seconds = original_user[:createdTimestamp]/1000
      user[:created_at] = DateTime.strptime(seconds.to_s,'%s')
    end
    user[:username] = original_user[:username]
    user[:email] = original_user[:email]
    user[:user_type] = original_user[:attributes][:userType].first
    user[:first_name] = original_user[:firstName] if original_user[:firstName]
    user[:last_name] = original_user[:lastName] if original_user[:lastName]
    user[:phone_number] = original_user[:attributes][:phone_number].first if original_user[:attributes][:phone_number]
    user
  end
end
