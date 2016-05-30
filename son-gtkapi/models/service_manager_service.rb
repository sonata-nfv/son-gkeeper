##
## Copyright 2015-2017 Portugal Telecom Inovacao/Altice Labs
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
# encoding: utf-8
class ServiceManagerService
  class << self
    
    # We're not yet using this: it allows for multiple implementations, such as Fakes (for testing)
    def implementation
      @implementation
    end
    
    def implementation=(impl)
      @implementation = impl
    end
  
    def find_services_by_uuid(uuid)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        response = RestClient.get( GtkApi.settings.srvmgmt+"/services/#{uuid}", headers)
      rescue => e
        puts "ServiceManagerService#create: e=#{e.backtrace}"
        nil 
      end
    end
    
    def find_services(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      pp "ServiceManagerService#find_services(#{params}): headers=#{headers}"
      begin
        response = RestClient.get(GtkApi.settings.srvmgmt+'/services', headers) 
        pp "ServiceManagerService#find_services(#{params}): response=#{response}"
        JSON.parse response.body
      rescue => e
        puts "ServiceManagerService#create: e=#{e.backtrace}"
        nil 
      end
    end

    def find_requests(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      pp "ServiceManagerService#find_requests(#{params}): headers=#{headers}"
      begin
        uri = GtkApi.settings.srvmgmt+'/requests'
        RestClient.get(uri, headers) 
      rescue => e
        puts "ServiceManagerService#create: e=#{e.backtrace}"
        nil 
      end
    end
    
    def find_requests_by_uuid(uuid)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        response = RestClient.get( GtkApi.settings.srvmgmt+"/requests/#{uuid}", headers)
      rescue => e
        puts "ServiceManagerService#create: e=#{e.backtrace}"
        nil 
      end
    end
    
    def create(params)
      pp "ServiceManagerService#create(#{params})"
      begin
        uri = GtkApi.settings.srvmgmt+'/requests'
        response = RestClient.post(uri, { service_uuid: params[:service_uuid]}, content_type: :json, accept: :json) 
        pp "ServiceManagerService#create: response="+response
        parsed_response = JSON.parse(response)
        pp "ServiceManagerService#create: parsed_response=#{parsed_response}"
        parsed_response
      rescue => e
        puts "ServiceManagerService#create: e=#{e.backtrace}"
        nil 
      end      
    end
    
    def get_log
      RestClient.get(GtkApi.settings.srvmgmt+"/admin/logs")      
    end
  end
end
