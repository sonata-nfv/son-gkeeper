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
require_relative '../spec_helper'
require 'securerandom'

RSpec.describe GtkSrv, type: :controller do 
  include Rack::Test::Methods
  def app() GtkSrv end

  # let(:n_service) {build(:n_service, catalogues: 'http://localhost:5200/catalogues')}
  let(:services_catalogue) { 'http://sp.int3.sonata-nfv.eu:4002/catalogues/api/v2/network-services'}#GtkSrv.services_catalogue.url }
  let(:functions_catalogue) { 'http://sp.int3.sonata-nfv.eu:4002/catalogues/api/v2/vnfs'}
  let(:suuid) { '8153f2ea-8da2-4d60-9dde-ff613501ce7a'}
  let(:si_uuid) { '1401ff3c-576f-4376-b00d-0d10caaee184'}
  let(:service_creation_request) {{
        began_at: "2018-01-23T17:04:41.339Z", 
        callback: nil, 
        request_type: "CREATE", 
        service_uuid: suuid 
    }}
  let(:service_creation_response) {service_creation_request.merge!({
        created_at: "2018-01-23T17:04:41.427Z", 
        id: "10903fae-d1da-4d83-98fa-c2e6b17764ed", 
        service_instance_uuid: si_uuid, 
        status: "NEW", 
        updated_at: "2018-01-23T17:04:41.427Z"
  })}
  let(:service_termination_request) {{
        began_at: "2018-01-23T17:04:41.339Z", 
        callback: nil, 
        request_type: "TERMINATE", 
        service_instance_uuid: si_uuid,
        service_uuid: suuid 
    }}
  let(:service_termination_response) {service_termination_request.merge!({
        created_at: "2018-01-23T17:04:41.427Z", 
        id: "10903fae-d1da-4d83-98fa-c2e6b17764ed", 
        status: "NEW", 
        updated_at: "2018-01-23T17:04:41.427Z"
  })}
  let(:stored_services) {[{:created_at=>"2018-03-14T14:45:55.996+00:00", :md5=>"26088f68dc0aff544378bec0edd1e17c", :nsd=>{:author=>"Luis Conceicao, UBIWHERE", :connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"input", :interface=>"ipv4", :type=>"external"}, {:id=>"output", :interface=>"ipv4", :type=>"external"}], :description=>"\"The network service descriptor for the SONATA PSA pilot,\n comprising VPN, TOR, PRX, FW and SSP functions functions\"\n", :descriptor_version=>"1.0", :forwarding_graphs=>[{:constituent_virtual_links=>["mgmt", "input-2-vpn", "vpn-2-prx", "prx-2-tor", "tor-2-vfw", "vfw-2-output"], :constituent_vnfs=>["vnf_vpn", "vnf_tor", "vnf_prx", "vnf_vfw"], :fg_id=>"fg01", :network_forwarding_paths=>[{:connection_points=>[{:connection_point_ref=>"input", :position=>1}, {:connection_point_ref=>"vnf_vpn:inout", :position=>2}, {:connection_point_ref=>"vnf_vpn:inout", :position=>3}, {:connection_point_ref=>"vnf_prx:inout", :position=>4}, {:connection_point_ref=>"vnf_prx:inout", :position=>5}, {:connection_point_ref=>"vnf_tor:inout", :position=>6}, {:connection_point_ref=>"vnf_tor:inout", :position=>7}, {:connection_point_ref=>"vnf_vfw:cpinput", :position=>8}, {:connection_point_ref=>"vnf_vfw:cpoutput", :position=>9}, {:connection_point_ref=>"output", :position=>10}], :fp_id=>"fg01:fp01", :policy=>"none"}], :number_of_endpoints=>2, :number_of_virtual_links=>6}], :name=>"psa-portal", :network_functions=>[{:vnf_id=>"vnf_vpn", :vnf_name=>"vpn-vnf", :vnf_vendor=>"eu.sonata-nfv", :vnf_version=>"0.9.9"}, {:vnf_id=>"vnf_tor", :vnf_name=>"tor-vnf", :vnf_vendor=>"eu.sonata-nfv", :vnf_version=>"0.9.9"}, {:vnf_id=>"vnf_prx", :vnf_name=>"prx-vnf", :vnf_vendor=>"eu.sonata-nfv", :vnf_version=>"0.9.9"}, {:vnf_id=>"vnf_vfw", :vnf_name=>"vfw-vnf", :vnf_vendor=>"eu.sonata-nfv", :vnf_version=>"0.0.8"}], :service_specific_managers=>[{:description=>"An SSM functioning as task, config and monitor SSM.", :id=>"sonssmpsaservicetask-config-monitor1", :image=>"sonatanfv/psaservice-ssm-taskconfigmonitor", :options=>[{:key=>"type", :value=>"task"}, {:key=>"type", :value=>"configure"}, {:key=>"type", :value=>"monitor"}]}], :vendor=>"eu.sonata-nfv.service-descriptor", :version=>"0.10.12", :virtual_links=>[{:connection_points_reference=>["vnf_vpn:mgmt", "vnf_tor:mgmt", "vnf_prx:mgmt", "vnf_vfw:cpmgmt", "mgmt"], :connectivity_type=>"E-LAN", :id=>"mgmt"}, {:connection_points_reference=>["input", "vnf_vpn:inout"], :connectivity_type=>"E-Line", :id=>"input-2-vpn"}, {:connection_points_reference=>["vnf_vpn:inout", "vnf_prx:inout"], :connectivity_type=>"E-Line", :id=>"vpn-2-prx"}, {:connection_points_reference=>["vnf_prx:inout", "vnf_tor:inout"], :connectivity_type=>"E-Line", :id=>"prx-2-tor"}, {:connection_points_reference=>["vnf_tor:inout", "vnf_vfw:cpinput"], :connectivity_type=>"E-Line", :id=>"tor-2-vfw"}, {:connection_points_reference=>["vnf_vfw:cpoutput", "output"], :connectivity_type=>"E-Line", :id=>"vfw-2-output"}]}, :signature=>"", :status=>"active", :updated_at=>"2018-03-14T14:45:55.996+00:00", :username=>"sonata", :uuid=>"8a4a3786-154d-4432-b329-20a0320956b4"}]}
  let(:stored_function_1) {{:created_at=>"2018-03-14T14:45:56.128+00:00", :md5=>"2db5852e91e981519bbd4788274b9296", :signature=>"", :status=>"active", 
    :updated_at=>"2018-03-14T14:45:56.128+00:00", :username=>"sonata", 
    :vnfd=>{
      :author=>"Felipe Vicens, ATOS", 
      :connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], 
      :description=>"Implementation of Proxy function", :descriptor_version=>"vnfd-schema-02", 
      :function_specific_managers=>[{:description=>"FSM for the configuration of the vPRX", :id=>"sonfsmpsaserviceprx-vnfprx-config1", :image=>"sonatanfv/psa-vprx-fsm-css", :options=>[{:key=>"type", :value=>"start"}, {:key=>"type", :value=>"stop"}, {:key=>"type", :value=>"configure"}]}], 
      :monitoring_rules=>[{:condition=>"vdu01:vm_cpu_perc > 90", :description=>"Trigger events if CPU load is above 90 percent.", :duration=>60, :duration_unit=>"s", :name=>"mon:rule:vm_cpu_perc", :notification=>[{:name=>"notification01", :type=>"rabbitmq_message"}]}, {:condition=>"vdu01:vm_mem_perc > 90", :description=>"Trigger events if memory consumption is above 90 percent.", :duration=>60, :duration_unit=>"s", :name=>"mon:rule:vm_mem_perc", :notification=>[{:name=>"notification02", :type=>"rabbitmq_message"}]}, {:condition=>"vdu01:traffic_http_in > 1500", :description=>"Trigger events if network http packets are over 1500.", :duration=>1, :duration_unit=>"s", :name=>"mon:rule:traffic_http_in", :notification=>[{:name=>"notification01", :type=>"rabbitmq_message"}]}], 
      :name=>"prx-vnf", :vendor=>"eu.sonata-nfv", :version=>"0.9.9", :virtual_deployment_units=>[{:connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :id=>"vdu01", :monitoring_parameters=>[{:name=>"vm_cpu_perc", :unit=>"Percentage"}, {:name=>"vm_mem_perc", :unit=>"Percentage"}, {:name=>"vm_net_rx_bps", :unit=>"bps"}, {:name=>"vm_net_tx_bps", :unit=>"bps"}, {:name=>"traffic_http_in", :unit=>"bps"}], :resource_requirements=>{:cpu=>{:vcpus=>1}, :memory=>{:size=>2, :size_unit=>"GB"}, :storage=>{:size=>20, :size_unit=>"GB"}}, :vm_image=>"http://files.sonata-nfv.eu/son-psa-pilot/prx-vnf/eu.sonata-nfv_vprx-vnf_0.1_vdu01", :vm_image_format=>"qcow2", :vm_image_md5=>"f3c6705dd692bb452640ce2b5d49a1e1"}], :virtual_links=>[{:connection_points_reference=>["vdu01:mgmt", "mgmt"], :connectivity_type=>"E-LAN", :dhcp=>true, :id=>"mgmt"}, {:connection_points_reference=>["vdu01:inout", "inout"], :connectivity_type=>"E-Line", :id=>"input-output"}]}, :uuid=>"9765f675-4e36-4a09-9cfd-9aa22665f3e8"}}
  let(:stored_function_2) {{:created_at=>"2018-03-14T14:45:56.317+00:00", :md5=>"46058230de06fedd78dfed4b36e35110", :signature=>"", :status=>"active", :updated_at=>"2018-03-14T14:45:56.317+00:00", :username=>"sonata", :vnfd=>{:author=>"Luis Conceicao, UBIWHERE", :connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :description=>"Implementation of OpenVPN function", :descriptor_version=>"vnfd-schema-02", :function_specific_managers=>[{:description=>"FSM for the configuration of the VPN", :id=>"sonfsmpsaservicevpn-vnfvpn-config1", :image=>"sonatanfv/psa-vpn-fsm-css", :options=>[{:key=>"type", :value=>"start"}, {:key=>"type", :value=>"configure"}]}], 
  :name=>"vpn-vnf", :vendor=>"eu.sonata-nfv", :version=>"0.9.9", :virtual_deployment_units=>[{:connection_points=>[{:id=>"eth0", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :id=>"vdu01", :monitoring_parameters=>[{:name=>"vm_cpu_perc", :unit=>"Percentage"}, {:name=>"vm_mem_perc", :unit=>"Percentage"}, {:name=>"vm_net_rx_bps", :unit=>"bps"}, {:name=>"vm_net_tx_bps", :unit=>"bps"}], :resource_requirements=>{:cpu=>{:vcpus=>1}, :memory=>{:size=>2, :size_unit=>"GB"}, :storage=>{:size=>40, :size_unit=>"GB"}}, :vm_image=>"http://files.sonata-nfv.eu/son-psa-pilot/vpn-vnf/sonata-vpn.qcow2", :vm_image_format=>"qcow2", :vm_image_md5=>"799b6db0c724b6552e092232a94a262a"}], :virtual_links=>[{:connection_points_reference=>["vdu01:eth0", "mgmt"], :connectivity_type=>"E-LAN", :dhcp=>true, :id=>"mgmt"}, {:connection_points_reference=>["vdu01:inout", "inout"], :connectivity_type=>"E-Line", :id=>"input-output"}]}, :uuid=>"5463c939-ab44-43a9-b7d9-d91fb92f45ff"}}
  let(:stored_function_3) {{:created_at=>"2018-03-14T14:45:56.128+00:00", :md5=>"2db5852e91e981519bbd4788274b9296", :signature=>"", :status=>"active", :updated_at=>"2018-03-14T14:45:56.128+00:00", :username=>"sonata", :vnfd=>{:author=>"Felipe Vicens, ATOS", :connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :description=>"Implementation of Proxy function", :descriptor_version=>"vnfd-schema-02", :function_specific_managers=>[{:description=>"FSM for the configuration of the vPRX", :id=>"sonfsmpsaserviceprx-vnfprx-config1", :image=>"sonatanfv/psa-vprx-fsm-css", :options=>[{:key=>"type", :value=>"start"}, {:key=>"type", :value=>"stop"}, {:key=>"type", :value=>"configure"}]}], :monitoring_rules=>[{:condition=>"vdu01:vm_cpu_perc > 90", :description=>"Trigger events if CPU load is above 90 percent.", :duration=>60, :duration_unit=>"s", :name=>"mon:rule:vm_cpu_perc", :notification=>[{:name=>"notification01", :type=>"rabbitmq_message"}]}, {:condition=>"vdu01:vm_mem_perc > 90", :description=>"Trigger events if memory consumption is above 90 percent.", :duration=>60, :duration_unit=>"s", :name=>"mon:rule:vm_mem_perc", :notification=>[{:name=>"notification02", :type=>"rabbitmq_message"}]}, {:condition=>"vdu01:traffic_http_in > 1500", :description=>"Trigger events if network http packets are over 1500.", :duration=>1, :duration_unit=>"s", :name=>"mon:rule:traffic_http_in", :notification=>[{:name=>"notification01", :type=>"rabbitmq_message"}]}], 
  :name=>"tor-vnf", :vendor=>"eu.sonata-nfv", :version=>"0.9.9", :virtual_deployment_units=>[{:connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :id=>"vdu01", :monitoring_parameters=>[{:name=>"vm_cpu_perc", :unit=>"Percentage"}, {:name=>"vm_mem_perc", :unit=>"Percentage"}, {:name=>"vm_net_rx_bps", :unit=>"bps"}, {:name=>"vm_net_tx_bps", :unit=>"bps"}, {:name=>"traffic_http_in", :unit=>"bps"}], :resource_requirements=>{:cpu=>{:vcpus=>1}, :memory=>{:size=>2, :size_unit=>"GB"}, :storage=>{:size=>20, :size_unit=>"GB"}}, :vm_image=>"http://files.sonata-nfv.eu/son-psa-pilot/prx-vnf/eu.sonata-nfv_vprx-vnf_0.1_vdu01", :vm_image_format=>"qcow2", :vm_image_md5=>"f3c6705dd692bb452640ce2b5d49a1e1"}], :virtual_links=>[{:connection_points_reference=>["vdu01:mgmt", "mgmt"], :connectivity_type=>"E-LAN", :dhcp=>true, :id=>"mgmt"}, {:connection_points_reference=>["vdu01:inout", "inout"], :connectivity_type=>"E-Line", :id=>"input-output"}]}, :uuid=>"9765f675-4e36-4a09-9cfd-9aa22665f3e8"}}
  let(:stored_function_4) {{:created_at=>"2018-03-14T14:45:56.317+00:00", :md5=>"46058230de06fedd78dfed4b36e35110", :signature=>"", :status=>"active", :updated_at=>"2018-03-14T14:45:56.317+00:00", :username=>"sonata", :vnfd=>{:author=>"Luis Conceicao, UBIWHERE", :connection_points=>[{:id=>"mgmt", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :description=>"Implementation of OpenVPN function", :descriptor_version=>"vnfd-schema-02", :function_specific_managers=>[{:description=>"FSM for the configuration of the VPN", :id=>"sonfsmpsaservicevpn-vnfvpn-config1", :image=>"sonatanfv/psa-vpn-fsm-css", :options=>[{:key=>"type", :value=>"start"}, {:key=>"type", :value=>"configure"}]}], 
  :name=>"vfw-vnf", :vendor=>"eu.sonata-nfv", :version=>"0.0.8", :virtual_deployment_units=>[{:connection_points=>[{:id=>"eth0", :interface=>"ipv4", :type=>"management"}, {:id=>"inout", :interface=>"ipv4", :type=>"external"}], :id=>"vdu01", :monitoring_parameters=>[{:name=>"vm_cpu_perc", :unit=>"Percentage"}, {:name=>"vm_mem_perc", :unit=>"Percentage"}, {:name=>"vm_net_rx_bps", :unit=>"bps"}, {:name=>"vm_net_tx_bps", :unit=>"bps"}], :resource_requirements=>{:cpu=>{:vcpus=>1}, :memory=>{:size=>2, :size_unit=>"GB"}, :storage=>{:size=>40, :size_unit=>"GB"}}, :vm_image=>"http://files.sonata-nfv.eu/son-psa-pilot/vpn-vnf/sonata-vpn.qcow2", :vm_image_format=>"qcow2", :vm_image_md5=>"799b6db0c724b6552e092232a94a262a"}], :virtual_links=>[{:connection_points_reference=>["vdu01:eth0", "mgmt"], :connectivity_type=>"E-LAN", :dhcp=>true, :id=>"mgmt"}, {:connection_points_reference=>["vdu01:inout", "inout"], :connectivity_type=>"E-Line", :id=>"input-output"}]}, :uuid=>"5463c939-ab44-43a9-b7d9-d91fb92f45ff"}}
  
  describe 'POST /requests' do
    it 'accepts new valid termination requests' do
      creation_request_post_body = {service_uuid: suuid, egresses: [], ingresses: [], user_data: {}, request_type: 'CREATE'}
      allow(Request).to receive(:create).and_return(service_creation_response)
      WebMock.stub_request(:get, services_catalogue+'/'+suuid).to_return(status: 200, body: stored_services.to_json)
      WebMock.stub_request(:get, functions_catalogue+"?name=vpn-vnf&vendor=eu.sonata-nfv&version=0.9.9").with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).to_return(status: 200, body: stored_function_1.to_json, headers: {})
      WebMock.stub_request(:get, functions_catalogue+"?name=prx-vnf&vendor=eu.sonata-nfv&version=0.9.9").with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).to_return(status: 200, body: stored_function_2.to_json, headers: {})
      WebMock.stub_request(:get, functions_catalogue+"?name=tor-vnf&vendor=eu.sonata-nfv&version=0.9.9").with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).to_return(status: 200, body: stored_function_3.to_json, headers: {})
      WebMock.stub_request(:get, functions_catalogue+"?name=vfw-vnf&vendor=eu.sonata-nfv&version=0.0.8").with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).to_return(status: 200, body: stored_function_4.to_json, headers: {})
      post '/requests', creation_request_post_body.to_json
      expect(last_response.status).to eq(201)
      
      termination_request_post_body = {service_instance_uuid: si_uuid, request_type: 'TERMINATE'}
      allow(Request).to receive(:where).and_return([service_creation_response])
      allow(Request).to receive(:create).and_return(service_termination_response)
      
      post '/requests', termination_request_post_body.to_json
      expect(last_response.status).to eq(201)
      
    end
  end
end
