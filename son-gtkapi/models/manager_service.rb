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
  
  #JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  CLASS_NAME = self.name
  LOG_MESSAGE = 'GtkApi::' + self.name
  
  def initialize(url, logger)
    method = 'GtkApi::' + CLASS_NAME + ".new(url=#{url}, logger=#{logger})"
    @url = url
    @logger = logger
    @logger.debug(method) {'entered'}
  end
  
  def self.getCurb(url:, params: {}, headers: {}, logger: nil)
    log_message=LOG_MESSAGE+'#getCurb'
    logger.debug() {"entered with url=#{url}, params=#{params}, headers=#{headers}, logger=#{logger.inspect}"} if logger
    res=Curl.get(params.empty? ? url : url + '?' + Curl::postalize(params)) do |req|
      headers.each do |h|
        logger.debug(log_message) {"header['" + h[0] + "]: '" + h[1] + "'"} if logger
        req.headers[h[0]] = h[1]
      end
    end
    logger.debug(log_message) {'header_str='+res.header_str} if logger
    res
  end
  
  def self.postCurb(url:, body:, logger: nil)
    log_message=LOG_MESSAGE+'#postCurb'
    logger.debug(log_message) {"entered with url=#{url}, body=#{body}, logger=#{logger.inspect}"} if logger
    res=Curl.post(url, body) do |req|
      req.headers['Content-type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
    end
    logger.debug(log_message) {"response=#{res.body}"} if logger
    res.body
  end
  
  def self.format_error(backtrace)
    first_line = backtrace[0].split(":")
    "In "+first_line[0].split("/").last+", "+first_line.last+": "+first_line[1]
  end
    
  def self.get_record_count_from_response_headers(header_str)
    # From http://stackoverflow.com/questions/14345805/get-response-headers-from-curb
    http_response, *http_headers = header_str.split(/[\r\n]+/).map(&:strip)
    http_headers = Hash[http_headers.flat_map{ |s| s.scan(/^(\S+): (.+)/) }]

    #http_response # => "HTTP/1.1 200 OK"
    #http_headers => { "Date" => "2013-01-10 09:07:42 -0700", "Content-Type" => "text/html", "Server" => "WEBrick/1.3.1 (Ruby/1.9.3/2012-11-10)",
    #        "Content-Length" => "62164", "Connection" => "Keep-Alive"}
    http_headers['X-Record-Count']
  end
end
