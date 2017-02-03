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
class ManagerService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  CLASS_NAME = self.name
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def initialize(url, logger)
    method = 'GtkApi::' + CLASS_NAME + ".new(url=#{url}, logger=#{logger})"
    @url = url
    @logger = logger
    @logger.debug(method) {'entered'}
  end
  
  def self.getCurb(url:, params: {}, headers: {}, logger: nil)
    log_message=LOG_MESSAGE+"##{__method__}"
    logger.debug(log_message) {"entered with url=#{url}, params=#{params}, headers=#{headers}, logger=#{logger.inspect}"} if logger
    complete_url = params.empty? ? url : url + '?' + Curl::postalize(params)
    logger.debug(log_message) {"complete_url=#{complete_url}"} if logger
    res=Curl.get(complete_url) do |req|
      headers.each do |h|
        logger.debug(log_message) {"header[#{h[0]}]: #{h[1]}"} if logger
        req.headers[h[0]] = h[1]
      end
    end
    logger.debug(log_message) {"header_str=#{res.header_str}"} if logger
    logger.debug(log_message) {"response body=#{res.body}"} if logger
    count = get_record_count_from_response_headers(res.header_str).to_i
    begin
      parsed_response = res.body.empty? ? {} : JSON.parse(res.body, symbolize_names: true)
      logger.debug(log_message) {"parsed_response=#{parsed_response}"} if logger
      {count: count, items: parsed_response}
    rescue => e
      logger.error(log_message) {"Error during processing: #{$!}"} if logger
      logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"} if logger
      nil 
    end
  end
  
  def self.postCurb(url:, body:, headers: {}, logger: nil)
    log_message=LOG_MESSAGE+"##{__method__}"
    logger.debug(log_message) {"entered with url=#{url}, body=#{body}, logger=#{logger.inspect}"} if logger
    res=Curl.post(url, body) do |req|
      if headers.empty?
        req.headers['Content-type'] = req.headers['Accept'] = 'application/json'
      else
        headers.each do |h|
          logger.debug(log_message) {"header[#{h[0]}]: #{h[1]}"} if logger
          req.headers[h[0]] = h[1]
        end
      end
    end
    logger.debug(log_message) {"response body=#{res.body}"} if logger
    begin
      parsed_response = JSON.parse(res.body, symbolize_names: true)
      logger.debug(log_message) {"parsed_response=#{parsed_response}"} if logger
      parsed_response
    rescue => e
      logger.error(log_message) {"Error during processing: #{$!}"} if logger
      logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"} if logger
      nil 
    end
  end
  
  private
  
  def self.format_error(backtrace)
    first_line = backtrace[0].split(":")
    "In "+first_line[0].split("/").last+", "+first_line.last+": "+first_line[1]
  end
    
  def self.get_header_from_response_headers(header_str)
    # From http://stackoverflow.com/questions/14345805/get-response-headers-from-curb
    http_response, *http_headers = header_str.split(/[\r\n]+/).map(&:strip)
    http_headers = Hash[http_headers.flat_map{ |s| s.scan(/^(\S+): (.+)/) }]

    #http_response # => "HTTP/1.1 200 OK"
    #http_headers => { "Date" => "2013-01-10 09:07:42 -0700", "Content-Type" => "text/html", "Server" => "WEBrick/1.3.1 (Ruby/1.9.3/2012-11-10)",
    #        "Content-Length" => "62164", "Connection" => "Keep-Alive"}
  end

  def self.get_record_count_from_response_headers(header_str)
    # From http://stackoverflow.com/questions/14345805/get-response-headers-from-curb
    http_response, *http_headers = header_str.split(/[\r\n]+/).map(&:strip)
    http_headers = Hash[http_headers.flat_map{ |s| s.scan(/^(\S+): (.+)/) }]

    #http_response # => "HTTP/1.1 200 OK"
    #http_headers => { "Date" => "2013-01-10 09:07:42 -0700", "Content-Type" => "text/html", "Server" => "WEBrick/1.3.1 (Ruby/1.9.3/2012-11-10)",
    #        "Content-Length" => "62164", "Connection" => "Keep-Alive"}
    http_headers['Record-Count']
  end
  
  def self.get_log(url:, log_message:'', logger: nil)
    logger.debug(log_message) {'entered'} if logger

    response=Curl.get( url) do |req|
      req.headers['Content-Type'] = 'text/plain; charset=utf8'
      req.headers['Location'] = '/'
    end    
    
    logger.debug(log_message) {'status=' + response.response_code.to_s} if logger
    case response.response_code
      when 200
        response.body
      else
        logger.error(log_message) {"Error during processing: #{$!}"} if logger
        logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"} if logger
        nil
      end
  end

  def self.find(url:, params: {}, headers: JSON_HEADERS, log_message:'', logger: nil)
    logger.debug(log_message) {'entered'}
    response = getCurb(url: url, params: params, headers: headers, logger: logger)
    logger.debug(log_message) {"response=#{response}"} if logger
    response
  end
end
