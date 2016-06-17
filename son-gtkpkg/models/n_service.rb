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
  
  attr_accessor :descriptor
  
  def initialize(catalogue, logger, folder)
    @catalogue = catalogue
    @url = @catalogue.url+'/network-services'
    @logger = logger
    @descriptor = {}
    if folder
      @folder = File.join(folder, "service_descriptors") 
      FileUtils.mkdir @folder unless File.exists? @folder
    end
  end
  
  def to_file(content)
    @logger.debug "NService.to_file(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def from_file(filename)
    @logger.debug "NService.from_file(#{filename})"
    @descriptor = YAML.load_file filename
    @logger.debug "NService.from_file: content = #{@descriptor}"
    @descriptor
  end
  
  def store()
    @logger.debug "NService.store(#{@descriptor})"
    service = duplicated_service?(@descriptor)
    service = @catalogue.create(@descriptor) unless service.any?
    @logger.debug "NService.store service #{service}"
    service
  end
  
  def find_by_uuid(uuid)
    @logger.debug "NService.find_by_uuid(#{uuid})"
    service = @catalogue.find_by_uuid(uuid)
    @logger.debug "NService.find_by_uuid: #{service}"
    service
  end
  
  private
  
  def duplicated_service?(descriptor)
    @catalogue.find({'vendor'=>descriptor['vendor'], 'name'=>descriptor['name'], 'version'=>descriptor['version']})
  end
end
