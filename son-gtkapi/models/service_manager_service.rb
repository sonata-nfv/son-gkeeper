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
        response = RestClient.get( GtkApi.settings.services['url']+"/services/#{uuid}", headers)
      rescue => e
        e.to_json
      end
    end
    
    def find_services(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      pp "ServiceManagerService#find_services(#{params}): headers=#{headers}"
      begin
        RestClient.get(GtkApi.settings.services['url']+'/services', headers) 
      rescue => e
        e.to_json 
      end
    end

    def find_requests(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      pp "ServiceManagerService#find_requests(#{params}): headers=#{headers}"
      begin
        RestClient.get(GtkApi.settings.services['url']+'/requests', headers) 
      rescue => e
        e.to_json 
      end
    end
  end
end
