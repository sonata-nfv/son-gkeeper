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

RSpec.describe GtkSrv, type: :controller do 
  include Rack::Test::Methods
  def app() GtkSrv end

  # let(:n_service) {build(:n_service, catalogues: 'http://localhost:5200/catalogues')}
  let(:services_catalogue) { 'http://sp.int3.sonata-nfv.eu:4002/catalogues/api/v2/network-services'}#GtkSrv.services_catalogue.url }
  let(:functions_catalogue) { 'http://sp.int3.sonata-nfv.eu:4002/catalogues/api/v2/vnfs'}
  let(:suuid) { '8153f2ea-8da2-4d60-9dde-ff613501ce7a'}
  let(:service_creation_request) {{
        began_at: "2018-01-23T17:04:41.339Z", 
        callback: nil, 
        request_type: "CREATE", 
        service_uuid: suuid 
    }}
  let(:service_creation_response) {service_creation_request.merge!({
        created_at: "2018-01-23T17:04:41.427Z", 
        id: "10903fae-d1da-4d83-98fa-c2e6b17764ed", 
        service_instance_uuid: nil, 
        status: "NEW", 
        updated_at: "2018-01-23T17:04:41.427Z"
  })}
  let(:stored_service) {[
    {
        "created_at": "2018-03-13T23:53:33.949+00:00", 
        "md5": "2e5e1116c4a1b8c7485fb0e8cfa08302", 
        "nsd": {
            "author": "Thomas Soenen", 
            "connection_points": [
                {
                    "id": "mgmt", 
                    "interface": "ipv4", 
                    "type": "management"
                }, 
                {
                    "id": "input", 
                    "interface": "ipv4", 
                    "type": "external"
                }, 
                {
                    "id": "output", 
                    "interface": "ipv4", 
                    "type": "external"
                }
            ], 
            "description": "vFoward for 2 VNFs on 1 PoPs.", 
            "descriptor_version": "1.0", 
            "forwarding_graphs": [
                {
                    "constituent_vnfs": [
                        "vforward_vnf_1_1", 
                        "vforward_vnf_2_1"
                    ], 
                    "fg_id": "ns:fg01", 
                    "network_forwarding_paths": [
                        {
                            "connection_points": [
                                {
                                    "connection_point_ref": "input", 
                                    "position": 1
                                }, 
                                {
                                    "connection_point_ref": "vforward_vnf_1_1:input", 
                                    "position": 2
                                }, 
                                {
                                    "connection_point_ref": "vforward_vnf_1_1:output", 
                                    "position": 3
                                }, 
                                {
                                    "connection_point_ref": "vforward_vnf_2_1:input", 
                                    "position": 4
                                }, 
                                {
                                    "connection_point_ref": "vforward_vnf_2_1:output", 
                                    "position": 5
                                }, 
                                {
                                    "connection_point_ref": "output", 
                                    "position": 6
                                }
                            ], 
                            "fp_id": "ns:fg01:fp01", 
                            "policy": "none"
                        }
                    ], 
                    "number_of_endpoints": 2, 
                    "number_of_virtual_links": 3
                }
            ], 
            "name": "vfoward-2-1", 
            "network_functions": [
                {
                    "vnf_id": "vforward_vnf_1_1", 
                    "vnf_name": "vforward-vnf-1-1", 
                    "vnf_vendor": "everything-must-go", 
                    "vnf_version": "0.1.1"
                }, 
                {
                    "vnf_id": "vforward_vnf_2_1", 
                    "vnf_name": "vforward-vnf-2-1", 
                    "vnf_vendor": "everything-must-go", 
                    "vnf_version": "0.2.1"
                }
            ], 
            "service_specific_managers": [
                {
                    "description": "monitoring SSM.", 
                    "id": "sonssmvforwardtask-config-monitor1", 
                    "image": "tsoenen/vforward-monitor", 
                    "options": [
                        {
                            "key": "type", 
                            "value": "monitor"
                        }
                    ]
                }
            ], 
            "vendor": "eu.sonata-nfv", 
            "version": "0.2.1", 
            "virtual_links": [
                {
                    "connection_points_reference": [
                        "mgmt", 
                        "vforward_vnf_1_1:mgmt", 
                        "vforward_vnf_2_1:mgmt"
                    ], 
                    "connectivity_type": "E-LAN", 
                    "id": "mgmt"
                }, 
                {
                    "connection_points_reference": [
                        "input", 
                        "vforward_vnf_1_1:input"
                    ], 
                    "connectivity_type": "E-Line", 
                    "id": "link_1"
                }, 
                {
                    "connection_points_reference": [
                        "vforward_vnf_1_1:output", 
                        "vforward_vnf_2_1:input"
                    ], 
                    "connectivity_type": "E-Line", 
                    "id": "link_2"
                }, 
                {
                    "connection_points_reference": [
                        "vforward_vnf_2_1:output", 
                        "output"
                    ], 
                    "connectivity_type": "E-Line", 
                    "id": "link_3"
                }
            ]
        }, 
        "signature": '', 
        "status": "active", 
        "updated_at": "2018-03-13T23:53:33.949+00:00", 
        "user_licence": "public", 
        "username": "sonata", 
        "uuid": "b84c135e-4617-4b51-a152-e0d01e3c27fa"
    }
  ]}
  let(:stored_function_1) {[
    "created_at": "2018-03-13T23:53:33.949+00:00", 
    "md5": "2e5e1116c4a1b8c7485fb0e8cfa08302", 
    "vnfd": {
      "vendor": "everything-must-go",
      "name": "vforward-vnf-1-1",
      "version": "0.1.1"
    },
    "uuid": "b84c135e-4617-4b51-a152-e0d01e3c27fa"
  ]}
  let(:stored_function_2) {[
    "created_at": "2018-03-13T23:53:33.949+00:00", 
    "md5": "2e5e1116c4a1b8c7485fb0e8cfa08302", 
    "vnfd": {
      "vendor": "everything-must-go",
      "name": "vforward-vnf-2-1",
      "version": "0.2.1"
    },
    "uuid": "b84c135e-4617-4b51-a152-e0d01e3c27fa"
  ]}
  
  describe 'POST /requests' do
    it 'accepts new valid (instantiations) requests' do
      post_body = {service_uuid: suuid, egresses: [], ingresses: [], user_data: {}, request_type: 'CREATE'}
      allow(Request).to receive(:create).and_return(service_creation_response)
      
      WebMock.stub_request(:get, services_catalogue+'/'+suuid).to_return(status: 200, body: stored_service)
      f_url_1 = "#{functions_catalogue}?name=vforward-vnf-1-1&vendor=everything-must-go&version=0.1.1"
      WebMock.stub_request(:get, f_url_1).to_return(status: 200, body: stored_function_1)
      f_url_2 = "#{functions_catalogue}?name=vforward-vnf-2-1&vendor=everything-must-go&version=0.2.1"
      WebMock.stub_request(:get, f_url_2).to_return(status: 200, body: stored_function_2)
      post '/requests', post_body.to_json
      expect(last_response.status).to eq(201)
    end
    it 'publishes the instantiation request'
    it 'processes the answer to the instantiation request'
    it 'rejects new invalid (instantiations) requests'
  end
end
