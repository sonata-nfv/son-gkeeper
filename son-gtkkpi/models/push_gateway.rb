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
class PushGateway
  def self.postCurb(url:, body:, headers: {})
    log_message="PushGateway##{__method__}"
    GtkApi.logger.debug(log_message) {"entered with url=#{url}, body=#{body} headers=#{headers}"}
    res=Curl.post(url, body.to_json) do |req|
      if headers.empty?
        req.headers['Content-type'] = req.headers['Accept'] = 'application/json'
      else
        headers.each do |h|
          GtkApi.logger.debug(log_message) {"header[#{h[0]}]: #{h[1]}"}
          req.headers[h[0]] = h[1]
        end
      end
    end
    GtkApi.logger.debug(log_message) {"response body=#{res.body}"}
    status = status_from_response_headers(res.header_str)
    case status
    when 200..202
      begin
        parsed_response = JSON.parse(res.body, symbolize_names: true)
        GtkApi.logger.debug(log_message) {"status #{status}, parsed_response=#{parsed_response}"}
        {status: status, count: 1, items: parsed_response, message: "OK"}
      rescue => e
        GtkApi.logger.error(log_message) {"Error during processing: #{$!}"} 
        GtkApi.logger.error(log_message) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
        {status: nil, count: nil, items: nil, message: "Error processing #{$!}: \n\t#{e.backtrace.join("\n\t")}"}
      end
    when 400..499
      GtkApi.logger.error(log_message) {"Status #{status}"} 
      {status: status, count: nil, items: nil, message: "Status #{status}: could not process"}
    else
      GtkApi.logger.error(log_message) {"Status #{status}"} 
      {status: status, count: nil, items: nil, message: "Status #{status} unknown"}
    end
  end
end
