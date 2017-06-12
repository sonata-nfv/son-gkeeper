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
require 'active_support'

class ValidatorError < StandardError; end
class ValidatorGenericError < StandardError; end

class Validator < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name
  
  #attr_accessor :available, :until
  
  def self.config(url:)
    log_message = LOG_MESSAGE + '#' + __method__.to_s
    raise ArgumentError.new('Validator model can not be configured with nil or empty url') if (url.to_s.empty?)
    @@url = url
    GtkApi.logger.debug(log_message) {'entered with url='+url}
  end
  
  def self.valid_package?(file:)
    log_message = LOG_MESSAGE + '#'+__method__.to_s
    # /validate/package
    # POST {'source':'embedded', 'file':'...', 'syntax': True, 'integrity': True, 'topology':True}
    GtkApi.logger.debug(log_message) {'entered'}
    
    body = {source:'embedded', file: file, syntax: 'true', integrity: 'true', topology: 'true'}
    headers = {'Content-Type'=>'multipart/form-data'} #{'Content-Type'=>'text/html'}
    begin
      curl = Curl::Easy.new(@@url+'/validate/package')
      # curl.headers["Content-Type"] = "multipart/form-data"
      curl.multipart_form_post = true
      
      # data = File.read('/Users/haider/Pictures/lion.jpg')
      # curl.post_body=data
      curl.http_post( Curl::PostField.content('source', 'embedded'), Curl::PostField.file('file', file),
        Curl::PostField.content('syntax', 'true'), Curl::PostField.content('integrity', 'true'), Curl::PostField.content('topology', 'true')
      )                              
      GtkApi.logger.debug(log_message) {"curl.body_str=#{curl.body_str}"}
      #resp = postCurb(url: @@url+'/validate/package', body: body, headers: headers)
      resp = {status: ManagerService.status_from_response_headers(curl.header_str), items: [JSON.parse(curl.body_str)]}
      case resp[:status]
      when 200
        GtkApi.logger.debug(log_message) {"Validator result=#{resp[:items]}"}
        true
      when 400
        GtkApi.logger.error(log_message) {"Status 400: #{resp[:items]}"} 
        raise ValidatorError.new "Errors/warnings in validating the package: #{resp[:items]}"
      else
        GtkApi.logger.error(log_message) {"Status #{resp[:status]}"} 
        raise ValidatorGenericError.new "Error #{resp[:status]} from the Package Validator"
      end
    rescue  => e
      GtkApi.logger.error(log_message) {"Error during processing: #{$!}"}
      GtkApi.logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      raise ValidatorGenericError.new "There was a problem POSTing a package file to the Package validator"
    end    
  end
end
