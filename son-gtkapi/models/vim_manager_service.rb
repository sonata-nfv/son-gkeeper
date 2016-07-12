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
class VimManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  
  def initialize(url, logger)
    @url = url
    @logger = logger
  end
    
  def find_vims(params)
    headers = JSON_HEADERS
    headers[:params] = params unless params.empty?
    begin
      response = RestClient.get( @url+"/vim", headers)
      @logger.debug "VimManagerService.find_vims(#{params}): response=#{response}"
      JSON.parse response.body
    rescue => e
      @logger.error "VimManagerService.find_vims: e=#{format_error(e.backtrace)}"
      nil 
    end
  end
  
  def create_vim(params)
    @logger.debug "VimManagerService.create_service_intantiation_request(#{params})"
    begin
      @logger.debug "VimManagerService.create_service_intantiation_request: @url = "+@url
      response = RestClient.post(@url+'/vim', params.to_json, content_type: :json, accept: :json) 
      @logger.debug "VimManagerService.create_service_intantiation_request: response="+response
      parsed_response = JSON.parse(response)
      @logger.debug "VimManagerService.create_service_intantiation_request: parsed_response=#{parsed_response}"
      parsed_response
    rescue => e
      @logger.error "VimManagerService.create_service_intantiation_request: #{e.message} - #{format_error(e.backtrace)}"
      nil 
    end      
  end
  
  def find_vim_request_by_uuid(uuid)
    headers = JSON_HEADERS
    headers[:params] = uuid
    begin
      response = RestClient.get( @url+"/vim_request/#{uuid}", headers)
      JSON.parse response.body
    rescue => e
      @logger.error "VimManagerService#find_requests_by_uuid: #{e.message} - #{format_error(e.backtrace)}"
      nil 
    end
  end
  
  def get_log
    method = "GtkApi::VimManagerService.get_log: "
    @logger.debug(method) {'entered'}
    full_url = @url+'/admin/logs'
    @logger.debug(method) {'url=' + full_url}
    RestClient.get(full_url)      
  end
  
  private
  
  def format_error(backtrace)
    first_line = backtrace[0].split(":")
    "In "+first_line[0].split("/").last+", "+first_line.last+": "+first_line[1]
  end
  
end
