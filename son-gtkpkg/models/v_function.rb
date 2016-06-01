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
require 'fileutils'

class VFunction
  
  def initialize(catalogue, logger, folder: nil)
    @catalogue = catalogue+'/vnfs'
    @logger = logger
    if folder
      @folder = File.join(folder, "function_descriptors")
      FileUtils.mkdir @folder unless File.exists? @folder
    end
  end
  
  def build(content)
    @logger.debug "VFunction.build(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def unbuild(path)
    @logger.debug "VFunction.unbuild("+path+")"
    content = YAML.load_file path
    @logger.debug "VFunction.unbuild: content = #{content}"
    content
  end
  
  def self.store_to_catalogue(vnfd)
    @logger.debug "VFunction.store(#{vnfd})"
    begin
      response = RestClient.post( @catalogue, vnfd.to_json, content_type: :json, accept: :json)     
      function = JSON.parse response
    rescue => e
      @logger.error e.response
      nil
    end
    @logger.debug "VFunction.store: function=#{function}"
    function
  end
  
  def load_from_catalogue(uuid)
    @logger.debug "VFunction.load(#{uuid})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.get(@catalogue+"/#{uuid}", headers) 
    @logger.debug "VFunction.load: #{response}"
    JSON.parse response.body
  end
  
end

#@@vnfr_schema=JSON.parse(JSON.dump(YAML.load(open('https://raw.githubusercontent.com/sonata-nfv/son-schema/master/function-record/vnfr-schema.yml'){|f| f.read})))
#...
#errors = validate_json(vnf_json,@@vnfr_schema)
#return 400, errors.to_json if errors