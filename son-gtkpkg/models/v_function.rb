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
  
  def initialize(folder)
    @folder = File.join(folder, "function_descriptors") 
    FileUtils.mkdir @folder unless File.exists? @folder
  end
  
  # {"descriptor_version"=>"vnfd-schema-01", "vendor"=>"eu.sonata-nfv", "name"=>"firewall-vnf", "version"=>"0.2", "author"=>"Steven van Rossem, iMinds", "description"=>"\"A first firewall VNF descriptor\"\n", "virtual_deployment_units"=>[{"id"=>"vdu01", "vm_image"=>"file:///docker_files/firewall/Dockerfile", "vm_image_format"=>"docker", "resource_requirements"=>{"cpu"=>{"vcpus"=>1}, "memory"=>{"size"=>2, "size_unit"=>"GB"}, "storage"=>{"size"=>10, "size_unit"=>"GB"}}, "connection_points"=>[{"id"=>"vdu01:cp01", "type"=>"interface"}, {"id"=>"vdu01:cp02", "type"=>"interface"}, {"id"=>"vdu01:cp03", "type"=>"interface"}]}], "virtual_links"=>[{"id"=>"mgmt", "connectivity_type"=>"E-LAN", "connection_points_reference"=>["vdu01:cp01", "vnf:mgmt"]}, {"id"=>"input", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vdu01:cp02", "vnf:input"]}, {"id"=>"output", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vdu01:cp03", "vnf:output"]}], "connection_points"=>[{"id"=>"vnf:mgmt", "type"=>"interface"}, {"id"=>"vnf:input", "type"=>"interface"}, {"id"=>"vnf:output", "type"=>"interface"}]}
  def build(content)
    pp "VFunction.build(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def unbuild(filename)
    pp "VFunction.unbuild()"
    File.open(File.join( @folder, filename), 'r') {|f| YAML.load_file(filename, f) }
  end
  
  def store_to_catalogue(vnfd)
    pp "VFunction.store(#{vnfd})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.post( Gtkpkg.settings.catalogues['url']+"/vnfs", :params => vnfd.to_json, :headers=>headers)     
    pp "VFunction.store: #{response}"
    JSON.parse response.body
  end
  
  def load_from_catalogue(uuid)
    pp "VFunction.load(#{uuid})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.get( Gtkpkg.settings.catalogues['url']+"/vnfs/#{uuid}", headers) 
    pp "VFunction.load: #{response}"
    JSON.parse response.body
  end
  
end

#@@vnfr_schema=JSON.parse(JSON.dump(YAML.load(open('https://raw.githubusercontent.com/sonata-nfv/son-schema/master/function-record/vnfr-schema.yml'){|f| f.read})))
#...
#errors = validate_json(vnf_json,@@vnfr_schema)
#return 400, errors.to_json if errors