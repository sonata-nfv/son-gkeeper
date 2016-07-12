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
class FunctionManagerService
    
    # We're not yet using this: it allows for multiple implementations, such as Fakes (for testing)
    attr_reader :url, :logger
    
    def initialize(url, logger)
      @url = url
      @logger = logger
    end
  
    def find_functions_by_uuid(uuid)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        response = RestClient.get( @url + "/functions/#{uuid}", headers)
      rescue => e
        @logger.error "FunctionManagerService#find_functions_by_uuid: e=#{e.backtrace}"
        nil 
      end
    end
    
    def find_functions(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      @logger.debug "FunctionManagerService#find_functions(#{params}): headers=#{headers}"
      begin
        response = RestClient.get(@url + '/functions', headers) 
        @logger.debug "FunctionManagerService#find_functions(#{params}): response=#{response}"
        JSON.parse response.body
      rescue => e
        @logger.error "FunctionManagerService#find_functions: e=#{e.backtrace}"
        nil 
      end
    end
    
    def get_log
      method = "GtkApi::FunctionManagerService.get_log: "
      @logger.debug(method) {'entered'}
      full_url = @url+'/admin/logs'
      @logger.debug(method) {'url=' + full_url}
      RestClient.get(full_url)      
    end
end
