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
require 'tempfile'
require './models/manager_service.rb'

class PackageManagerService < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name

  def self.url
    @@url
  end

  def self.config(url:)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    raise ArgumentError.new('PackageManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('PackageManagerService can not be configured with empty url') if url.empty?
    @@url = url
    GtkApi.logger.debug(method) {'@@url='+url}
  end

  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    uri = @@url+'/packages'
    raise ArgumentError.new('PackageManagerService can not be created without a user') unless params.key?(:user)
    user_params = params.delete(:user)
    user = User.find_by_name(user_params[:name])
    if user
      if user.authenticated?(user_params)
        GtkApi.logger.debug(method) {"User #{user_params[:name]} authenticated"}
        if user.authorized?(user_params)
          GtkApi.logger.debug(method) {"User #{user_params[:name]} authorized"}
          begin
            # from http://www.rubydoc.info/gems/rest-client/1.6.7/frames#Result_handling
            GtkApi.logger.debug(method) {"POSTing to "+uri+ " with params #{params}"}
            RestClient.post(uri, params){ |response, request, result, &block|
              GtkApi.logger.debug(method) {"response=#{response.inspect}"}
              case response.code
              when 201
                { status: 201, count: 1, data: JSON.parse(response.body, :symbolize_names => true), message: 'Created'}
              when 409
                { status: 409, count: 0, data: JSON.parse(response.body, :symbolize_names => true), message: 'Conflict'}
              when 400
                { status: 400, count: 0, data: {}, message: "Bad Request: #{params}"}
              else
                { status: response.code, count: 0, data: {}, message: 'Unexpected code'}
              end
            }
          rescue  => e #RestClient::Conflict
            GtkApi.logger.error(method) {"Error during processing: #{$!}"}
            GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
            { status: 500, count: 0, data: {}, message: e.backtrace.join("\n\t")}
          end
        else
          GtkApi.logger.debug(method) {"user #{params[:user][:name]} not authorized"}
          { status: 403, count: 0, data: {}, message: 'Forbidden: user '+params[:user][:name]+' could not be authorized'}
        end
      else
        GtkApi.logger.debug(method) {"user #{params[:user][:name]} not authenticated"}
        { status: 401, count: 0, data: {}, message: 'Unauthorized: user '+params[:user][:name]+' could not be authenticated'}
      end
    else
      GtkApi.logger.debug(method) {"user #{params[:user][:name]} not found"}
      { status: 404, count: 0, data: {}, message: 'User '+params[:user][:name]+' not found'}
    end
  end
  
  def self.find_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
    headers[:params] = uuid
    begin
      response = RestClient.get(@@url+"/packages/#{uuid}", headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      response
    rescue => e
      e.to_json
    end
  end

  def self.find(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params
    begin
      response = RestClient.get(@@url+'/packages', headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
  def self.delete(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    begin
      response = RestClient.delete(@@url+'/packages/'+uuid, headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
end
