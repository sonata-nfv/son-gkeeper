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
class LicenceManagerService < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  LICENCES_URL = '/api/v1/licenses/'
  
  def self.config(url:)
    method = LOG_MESSAGE + "#config(url=#{url})"
    raise ArgumentError.new('LicenceManagerService can not be configured with nil url') if url.nil?
    raise ArgumentError.new('LicenceManagerService can not be configured with empty url') if url.empty?
    @@url = url
    GtkApi.logger.debug(method) {'entered'}
  end
  
  def self.valid?(params)
    # service_uuid, string, mandatory
    # user_uuid, string, mandatory
    # license_uuid, string, mandatory
    # license_type, string, mandatory
    # description, string
    # validation_url, string
    # status, string, mandatory

    
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}
    raise ArgumentError, 'User must be valid' unless User.valid? params[:user_uuid]
    raise ArgumentError, 'Service must be valid' unless ServiceManagerService.valid? params[:service_uuid]
    GtkApi.logger.debug(method) {'Leaving with valid licence data'}
    true
  end
  
  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}
    headers = {'Content-Type'=>'application/x-www-form-urlencoded'}

    begin
      self.valid?(params)
      licence = postCurb(url: @@url+LICENCES_URL, body: params, headers: headers)
      GtkApi.logger.debug(method) {"licence=#{licence}"}
      
      case licence[:status]
      when 200, 201
        {status: 201, count: 1, items: licence[:data], message: 'Created'}
      else
        {status: licence[:status], count: 0, items: [], message: licence[:error]}
      end
    rescue  ArgumentError => ae
      {status: 422, count: 0, items:[], message: 'Unprocessable Entity'}
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      {error: 'Licence type not created', licence: e.backtrace}
    end
  end

  def self.find_by_uuid(uuid)
    log_message = LOG_MESSAGE + "##{__method__}(#{uuid})"
    GtkApi.logger.debug(log_message) {'entered'}

    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    licence = getCurb(url: @@url + LICENCES_URL + uuid + '/', params: {}, headers: headers)
    GtkApi.logger.debug(log_message) {"licence=#{licence}"}
    case licence[:status]
    when 200
      {status: 200, count: 1, items: licence[:items][:data][:licenses], message: "OK"}
    when 400
    when 404
      {status: licence[:status], count: 0, items: [], message: "Not Found"}
    else
      {status: licences[:status], count: 0, items: [], message: "Error"}
    end
  end
    
  def self.find(params)
    log_message = LOG_MESSAGE + "##{__method__}(#{params})"
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    GtkApi.logger.debug(log_message) {'entered'}
    licences = getCurb(url: @@url + LICENCES_URL, params: params, headers: headers)
    GtkApi.logger.debug(log_message) {"licences=#{licences}"}
    case licences[:status]
    when 200
      {status: 200, count: licences[:items][:data][:licenses].count, items: licences[:items][:data][:licenses], message: "OK"}
    when 400
    when 404
      {status: 200, count: 0, items: [], message: "OK"}
    else
      {status: licences[:status], count: 0, items: [], message: "Error"}
    end
  end
  
  #def user
  #  @user ||= User.find(params[:user_id]) || halt(404)
  #end

  #def service
   # @service ||= user.services.find(params[:service_id]) || halt(404)
  #end

  #def task_date
  #  @task_date ||= Date.iso8601(params[:task_date])
  #rescue ArgumentError
  #  halt 400
  #end

  #def tasks
  #  @tasks ||= project.tasks_due_on(task_date)
  #end
  
  # now use this with
  #get '/users/:user_id/projects/:project_id/tasks-due-on/:task_date' do
  #  tasks.to_json
  #end
end
