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

class User < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  USERS_URL = '/users/'
  
  attr_accessor :uuid, :name, :session
  
  def self.config(url:)
    method = LOG_MESSAGE + "#config(url=#{url})"
    raise ArgumentError.new('UserManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('UserManagerService can not be configured with empty url') if url.empty?
    @@url = url
    GtkApi.logger.debug(method) {'entered'}
  end
  
  def initialize(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    @name = params[:name]
    @password = params[:password]
    @session = @uuid = nil
  end

  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}
    #headers = {'Content-Type'=>'application/x-www-form-urlencoded'}
    headers ={}
    begin
      user = postCurb(url: @@url+USERS_URL, body: params, headers: headers)
      GtkApi.logger.debug(method) {"user=#{user.body}"}
      JSON.parse user.body
    rescue  => e #RestClient::Conflict
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      {error: 'User not created', user: e.backtrace}
    end
  end

  # TODO
  def authenticated?(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with password #{params}"}
    @session = {began_at: Time.now.utc}
    @name == params[:name] && @password == params[:password] ? self : nil
  end
  
  def logout!
    session_lasted_for = Time.now.utc - @user_session[:began_at]
    @user_session = nil
    session_lasted_for
  end
  
  # TODO
  def authorized?(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    true
  end
  
  # TODO
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
    name=='Unknown' ? User.new({name: 'Unknown', password: 'None'}) : nil
  end

  def self.find(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    params[:name]=='Unknown' && params[:password]=='None' ? User.new(params) : nil
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
end
