## SONATA - Gatekeeper
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
require 'curb'
require 'json'

class NServiceNotFoundError < StandardError; end
class NServicesNotFoundError < StandardError; end

class NService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  
  def initialize(catalogue, logger)
    @catalogue = catalogue
    @logger = logger
  end
  
  def find(params)
    @logger.debug "NService.find(#{params})"
    begin
      services = @catalogue.find(params)
      @logger.debug "NService.find: #{services}"
      services
    rescue CatalogueRecordsNotFoundError
      raise NServicesNotFoundError.new "Services with params #{params} were not found"
    end
  end

  #def find_by_uuid(uuid)
  #  raise ArgumentError.new('NService.find_by_uuid: no UUID has been provided') if uuid.empty?
  #  @logger.debug "NService.find_by_uuid(#{uuid})"
  #  begin
  #    service = @catalogue.find_by_uuid(uuid)
  #    @logger.debug "NService.find_by_uuid: #{service}"
  #    service.is_a?(Array) ? service.first : service
  #  rescue CatalogueRecordNotFoundError
  #    raise NServiceNotFoundError.new 'Service with uuid '+uuid+' was not found'
  #  rescue Exception => e
  #    @logger.debug(e.message)
  #    @logger.debug(e.backtrace.inspect)
  #    halt 500, 'Could not contact the Service Catalogue'
  #  end
  #end
  
  def find_by_uuid(uuid)
    log_message='NService.'+__method__.to_s
    raise ArgumentError.new(log_message + ': no UUID has been provided') if uuid.empty?
    @logger.debug(log_message) {"entered with uuid=#{uuid}"}
    begin
      res=Curl.get(@catalogue.url) do |req|
        req.headers['Content-type'] = req.headers['Accept'] = 'application/json'
      end
      @logger.debug(log_message) {"header_str=#{res.header_str}"}
      @logger.debug(log_message) {"response body=#{res.body}"}
      status = status_from_response_headers(res.header_str)
      case status
      when 200
        begin
          parsed_response = res.body.empty? ? {} : JSON.parse(res.body, symbolize_names: true)
          @logger.debug(log_message) {"parsed_response=#{parsed_response}"}
          {status: 200, count: 1, items: parsed_response, message: "OK"}
        rescue => e
          @logger.error(log_message) {"Error during processing: #{$!}"}
          @logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
        end
      else
        raise NServiceNotFoundError.new 'Service with uuid '+uuid+' was not found'
      end
    rescue Curl::Err::ConnectionFailedError => e
      {status: 500, count: nil, items: nil, message: "Couldn't connect to server #{@catalogue.url}"}
    rescue Curl::Err::CurlError => e
      {status: 500, count: nil, items: nil, message: "Generic error while connecting to server #{@catalogue.url}"}
    rescue Curl::Err::AccessDeniedError => e
      {status: 500, count: nil, items: nil, message: "Access denied while connecting to server #{@catalogue.url}"}
    rescue Curl::Err::TimeoutError => e
      {status: 500, count: nil, items: nil, message: "Time out while connecting to server #{@catalogue.url}"}
    rescue Curl::Err::HostResolutionError => e
      {status: 500, count: nil, items: nil, message: "Couldn't resolve host name #{@catalogue.url}"}
    end
  end
  
  private
  
  def status_from_response_headers(header_str)
    # From http://stackoverflow.com/questions/14345805/get-response-headers-from-curb
    #http_response # => "HTTP/1.1 200 OK"
    http_status = header_str.split(/[\r\n]+/).map(&:strip)[0].split(" ")
    http_status[1].to_i
  end
end
