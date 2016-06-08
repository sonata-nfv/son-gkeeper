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
class VFunction
  
  def initialize(catalogue, logger)
    @catalogue = catalogue
    @logger = logger
  end
  
  def find_function(name,vendor,version)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    url = @catalogue.url+"?name=#{name}&vendor=#{vendor}&version=#{version}"
    begin
      response = RestClient.get(url, headers)
    rescue => e
      @logger.error "No function found for "+url
      e.message
    end
  end
end