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
  
  attr_accessor :descriptor
  
  def initialize(catalogue, logger, folder)
    @catalogue = catalogue
    @logger = logger
    @descriptor = {}
    if folder
      @folder = File.join(folder, "function_descriptors")
      FileUtils.mkdir @folder unless File.exists? @folder
    end
  end
  
  def to_file(content)
    @logger.debug "VFunction.to_file(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def from_file(path)
    @logger.debug "VFunction.from_file("+path+")"
    @descriptor = YAML.load_file path
    @logger.debug "VFunction.from_file: content = #{@descriptor}"
    @descriptor
  end
  
  def store
    @logger.debug "VFunction.store(#{@descriptor})"
    function = duplicated_function?(@descriptor)
    function = @catalogue.create(@descriptor) unless function.size    
    @logger.debug "VFunction.stored function #{function}"
    function
  end
  
  def find_by_uuid(uuid)
    @logger.debug "VFunction.find_by_uuid(#{uuid})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.get(@catalogue+"/#{uuid}", headers) 
    @logger.debug "VFunction.find_by_uuid: #{response}"
    JSON.parse response.body
  end
  
  private
  
  def duplicated_function?(descriptor)
    @catalogue.find({params: {vendor: descriptor['vendor'], name: descriptor['name'], version: descriptor['version']}})
  end
end
