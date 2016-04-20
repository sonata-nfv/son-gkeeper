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
  
  #{"descriptor_version"=>"1.0", "vendor"=>"eu.sonata-nfv.service-descriptor", "name"=>"sonata-demo", "version"=>"0.2", "author"=>"Michael Bredel, NEC Labs Europe", "description"=>"\"The network service descriptor for the SONATA demo,\n comprising iperf, a firewall, and tcpump.\"\n", "network_functions"=>[{"vnf_id"=>"vnf_firewall", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"firewall-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_iperf", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"iperf-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_tcpdump", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"tcpdump-vnf", "vnf_version"=>"0.1"}], "connection_points"=>[{"id"=>"ns:mgmt", "type"=>"interface"}, {"id"=>"ns:input", "type"=>"interface"}, {"id"=>"ns:output", "type"=>"interface"}], "virtual_links"=>[{"id"=>"mgmt", "connectivity_type"=>"E-LAN", "connection_points_reference"=>["vnf_iperf:mgmt", "vnf_firewall:mgmt", "vnf_tcpdump:mgmt", "ns:mgmt"]}, {"id"=>"input-2-iperf", "connectivity_type"=>"E-Line", "connection_points_reference"=>["ns:input", "vnf_iperf:input"]}, {"id"=>"iperf-2-firewall", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_iperf:output", "vns_firewall:input"]}, {"id"=>"firewall-2-tcpdump", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vns_firewall:output", "vnf_tcpdump:input"]}, {"id"=>"tcpdump-2-output", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_firewall:output", "ns:output"]}], "forwarding_graphs"=>[{"fg_id"=>"ns:fg01", "number_of_endpoints"=>2, "number_of_virtual_links"=>4, "constituent_vnfs"=>["vnf_iperf", "vnf_firewall", "vnf_tcpdump"], "network_forwarding_paths"=>[{"fp_id"=>"ns:fg01:fp01", "policy"=>"none", "connection_points"=>[{"connection_point_ref"=>"ns:input", "position"=>1}, {"connection_point_ref"=>"vnf_iperf:input", "position"=>2}, {"connection_point_ref"=>"vnf_iperf:output", "position"=>3}, {"connection_point_ref"=>"vnf_firewall:input", "position"=>4}, {"connection_point_ref"=>"vnf_firewall:output", "position"=>5}, {"connection_point_ref"=>"vnf_tcpdump:input", "position"=>6}, {"connection_point_ref"=>"vnf_tcpdump:output", "position"=>7}, {"connection_point_ref"=>"ns:output", "position"=>8}]}]}]}
  def build(content)
    pp "NService.build(#{content})"
    filename = content['name'].split('/')[-1]
    File.open(File.join( @folder, filename), 'w') {|f| YAML.dump(content, f) }
  end
  
  def unbuild(filename)
    pp "NService.unbuild(#{filename})"
    File.open(File.join( @folder, filename), 'r') do |f|
      content = YAML.load_file(filename, f)
    end
    pp "NService.unbuild: content = #{content}"
    content = {"descriptor_version"=>"1.0", "vendor"=>"eu.sonata-nfv.service-descriptor", "name"=>"sonata-demo", "version"=>"0.2", "author"=>"Michael Bredel, NEC Labs Europe", "description"=>"\"The network service descriptor for the SONATA demo,\n comprising iperf, a firewall, and tcpump.\"\n", "network_functions"=>[{"vnf_id"=>"vnf_firewall", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"firewall-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_iperf", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"iperf-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_tcpdump", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"tcpdump-vnf", "vnf_version"=>"0.1"}], "connection_points"=>[{"id"=>"ns:mgmt", "type"=>"interface"}, {"id"=>"ns:input", "type"=>"interface"}, {"id"=>"ns:output", "type"=>"interface"}], "virtual_links"=>[{"id"=>"mgmt", "connectivity_type"=>"E-LAN", "connection_points_reference"=>["vnf_iperf:mgmt", "vnf_firewall:mgmt", "vnf_tcpdump:mgmt", "ns:mgmt"]}, {"id"=>"input-2-iperf", "connectivity_type"=>"E-Line", "connection_points_reference"=>["ns:input", "vnf_iperf:input"]}, {"id"=>"iperf-2-firewall", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_iperf:output", "vns_firewall:input"]}, {"id"=>"firewall-2-tcpdump", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vns_firewall:output", "vnf_tcpdump:input"]}, {"id"=>"tcpdump-2-output", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_firewall:output", "ns:output"]}], "forwarding_graphs"=>[{"fg_id"=>"ns:fg01", "number_of_endpoints"=>2, "number_of_virtual_links"=>4, "constituent_vnfs"=>["vnf_iperf", "vnf_firewall", "vnf_tcpdump"], "network_forwarding_paths"=>[{"fp_id"=>"ns:fg01:fp01", "policy"=>"none", "connection_points"=>[{"connection_point_ref"=>"ns:input", "position"=>1}, {"connection_point_ref"=>"vnf_iperf:input", "position"=>2}, {"connection_point_ref"=>"vnf_iperf:output", "position"=>3}, {"connection_point_ref"=>"vnf_firewall:input", "position"=>4}, {"connection_point_ref"=>"vnf_firewall:output", "position"=>5}, {"connection_point_ref"=>"vnf_tcpdump:input", "position"=>6}, {"connection_point_ref"=>"vnf_tcpdump:output", "position"=>7}, {"connection_point_ref"=>"ns:output", "position"=>8}]}]}]}
    content
  end
  
  def store_to_catalogue(nsd)
    pp "NService.store(#{nsd})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.post( Gtkpkg.settings.catalogues['url']+"/network-services", :params => nsd.to_json, :headers=>headers)     
    pp "NService.store: #{response}"
    JSON.parse response.body
  end
  
  def load_from_catalogue(uuid)
    pp "NService.load(#{uuid})"
    headers = {'Accept'=>'application/json', 'Content-Type'=>'application/json'}
    response = RestClient.get( Gtkpkg.settings.catalogues['url']+"/network-services/#{uuid}", headers) 
    pp "NService.load: #{response}"
    JSON.parse response.body
  end
end