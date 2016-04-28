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
require 'tempfile'
require 'pp'

class NService
  
  def initialize(folder)
    @folder = File.join(folder, "service_descriptors") 
    FileUtils.mkdir @folder unless File.exists? @folder
  end
  
  def build(content)
    pp "NService.build(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def self.unbuild(filename)
    pp "NService.unbuild(#{filename})"
    content = YAML.load_file filename
    pp "NService.unbuild: content = #{content}"
    content
  end
  
  def self.store_to_catalogue(nsd)
    pp "NService.store(#{nsd})"
    begin
      response = RestClient.post( Gtkpkg.settings.catalogues['url']+"/network-services", nsd.to_json, , content_type: :json, accept: :json)     
      package = JSON.parse response
    rescue => e
        puts e.response
        nil
    end
    pp "NService.store: package=#{package}"
    package
  end
  
  def load_from_catalogue(uuid)
    pp "NService.load(#{uuid})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.get( Gtkpkg.settings.catalogues['url']+"/network-services/#{uuid}", headers) 
    pp "NService.load: #{response}"
    JSON.parse response.body
  end
end