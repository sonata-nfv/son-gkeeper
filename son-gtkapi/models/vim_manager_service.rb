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

class VimManagerService < ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def initialize(url, logger)
    method = LOG_MESSAGE + ".new(url=#{url}, logger=#{logger})"
    #@url = url
    #@logger = logger
    super
    @logger.debug(method) {'entered'}
  end
    
  def find_vims(params)
    method = LOG_MESSAGE + ".find_vims(#{params})"
    @logger.debug(method) {'entered'}    
    begin
      response = getCurb(url:url, headers:JSON_HEADERS) 
      @logger.debug(method) {'response='+response.body}
      JSON.parse response.body
    rescue => e
      @@logger.error(method) {"Error during processing: #{$!}"}
      @@logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil 
    end
  end
  
  def create_vim(params)
    method = LOG_MESSAGE + ".create_vim(#{params})"
    @logger.debug(method) {"entered"}
    
    begin
      @logger.debug(method) {"@url = "+@url}
      #response = RestClient.post(@url+'/vim', params.to_json, content_type: :json, accept: :json) 
      response = postCurb(url: @url+'/vim', body: params.to_json) 
      @logger.debug(method) {"response="+response}
      response
    rescue => e
      @@logger.error(method) {"Error during processing: #{$!}"}
      @@logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil 
    end      
  end
  
  def find_vim_request_by_uuid(uuid)
    method = LOG_MESSAGE + ".find_vim_request_by_uuid(#{uuid})"
    @logger.debug(method) {'entered'}
    begin
      response = getCurb(url:@url+'/vim_request/'+uuid, headers: JSON_HEADERS) 
      JSON.parse response.body
    rescue => e
      @@logger.error(method) {"Error during processing: #{$!}"}
      @@logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil 
    end
  end
end
