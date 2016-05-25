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
  def find_function(name,vendor,version)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    begin
      parsed_url = GtkSrv.settings.catalogues['url']+"/vnfs#?name=#{name}&vendor=#{vendor}&version=#{version}"
      response = RestClient.get(parsed_url, headers)
    rescue => e
      e.to_json
    end
  end
end