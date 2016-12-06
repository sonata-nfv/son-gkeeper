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

RSpec.describe GtkApi, type: :controller do
  def app() GtkApi end
  
  let(:service_uuid) { SecureRandom.uuid}
  let(:non_existent_service_uuid) {"a525f7ae-803c-458b-9521-13e260639fcb"}
  let(:invalid_service_uuid) {"a525f7ae-803c"}
  let(:service1) {{
    author: "Felipe Vicens, Atos IT Solutions and Services Iberia",
    connection_points:[
      {id: "ns:mgmt", type: "interface"},
      {id: "ns:input", type: "interface"},
      {id: "ns:output", type: "interface"}
    ],
    created_at: "2016-11-11T10:21:00.007+00:00",
    description: "\"The network service descriptor for the SONATA demo,\n comprising a Virtual Traffic Classifier\"\n",
    descriptor_version: "1.0",
    forwarding_graphs:[{
      constituent_vnfs: ["vnf_vtc"],
      fg_id: "ns:fg01",
      network_forwarding_paths:[{
        connection_points:[
          {connection_point_ref: "ns:input", position:1},
          {connection_point_ref: "vnf_firewall:input", position:2},
          {connection_point_ref: "vnf_firewall:output", position:3},
          {connection_point_ref: "vnf_vtc:input", position:4},
          {connection_point_ref: "vnf_vtc:output", position:5},
          {connection_point_ref: "ns:output", position:6}
        ],
        fp_id: "ns:fg01:fp01", policy:"none"}
      ],
      number_of_endpoints: 2,
      number_of_virtual_links: 3
    }],
    name: "sonata-demo-1",
    network_functions:[
      {vnf_id: "vnf_vtc", vnf_name:"vtc-vnf", vnf_vendor: "eu.sonata-nfv", vnf_version:"0.1"},
      {vnf_id: "vnf_firewall", vnf_name: "fw-vnf", vnf_vendor: "eu.sonata-nfv", vnf_version: "0.1"}
    ],
    service_specific_managers:[{description:"An empty example SSM.", id:"ssmdumb", image:"sonatanfv/ssmdumb", options:[{key:"myKey",value:"myValue"}]}],
    status: "active",
    updated_at:"2016-11-11T10:21:00.007+00:00",
    vendor:"eu.sonata-nfv.service-descriptor",
    version:"0.1",
    virtual_links:[
      { connection_points_reference:["vnf_vtc:mgmt","vnf_firewall:mgmt","ns:mgmt"], connectivity_type:"E-LAN", id:"mgmt"},
      { connection_points_reference:["ns:input","vnf_firewall:input"], connectivity_type:"E-Line", id:"input-2-fw"},
      { connection_points_reference:["vnf_firewall:output","vnf_vtc:input"], connectivity_type:"E-Line", id:"fw-2-vtc"},
      { connection_points_reference:["vnf_vtc:output","ns:output"], connectivity_type:"E-Line", id:"vtc-2-output"}],
    uuid: service_uuid
  }}
  let(:service2) {{
    author: "Felipe Vicens, Atos IT Solutions and Services Iberia",
    connection_points:[
      {id: "ns:mgmt", type: "interface"},
      {id: "ns:input", type: "interface"},
      {id: "ns:output", type: "interface"}
    ],
    created_at: "2016-11-11T10:21:00.007+00:00",
    description: "\"The network service descriptor for the SONATA demo,\n comprising a Virtual Traffic Classifier\"\n",
    descriptor_version: "1.0",
    forwarding_graphs:[{
      constituent_vnfs: ["vnf_vtc"],
      fg_id: "ns:fg01",
      network_forwarding_paths:[{
        connection_points:[
          {connection_point_ref: "ns:input", position:1},
          {connection_point_ref: "vnf_firewall:input", position:2},
          {connection_point_ref: "vnf_firewall:output", position:3},
          {connection_point_ref: "vnf_vtc:input", position:4},
          {connection_point_ref: "vnf_vtc:output", position:5},
          {connection_point_ref: "ns:output", position:6}
        ],
        fp_id: "ns:fg01:fp01", policy:"none"}
      ],
      number_of_endpoints: 2,
      number_of_virtual_links: 3
    }],
    name: "sonata-demo-1",
    network_functions:[
      {vnf_id: "vnf_vtc", vnf_name:"vtc-vnf", vnf_vendor: "eu.sonata-nfv", vnf_version:"0.1"},
      {vnf_id: "vnf_firewall", vnf_name: "fw-vnf", vnf_vendor: "eu.sonata-nfv", vnf_version: "0.1"}
    ],
    service_specific_managers:[{description:"An empty example SSM.", id:"ssmdumb", image:"sonatanfv/ssmdumb", options:[{key:"myKey",value:"myValue"}]}],
    status: "active",
    updated_at:"2016-11-11T10:21:00.007+00:00",
    vendor:"eu.sonata-nfv.service-descriptor",
    version:"0.2",
    virtual_links:[
      { connection_points_reference:["vnf_vtc:mgmt","vnf_firewall:mgmt","ns:mgmt"], connectivity_type:"E-LAN", id:"mgmt"},
      { connection_points_reference:["ns:input","vnf_firewall:input"], connectivity_type:"E-Line", id:"input-2-fw"},
      { connection_points_reference:["vnf_firewall:output","vnf_vtc:input"], connectivity_type:"E-Line", id:"fw-2-vtc"},
      { connection_points_reference:["vnf_vtc:output","ns:output"], connectivity_type:"E-Line", id:"vtc-2-output"}],
    uuid: service_uuid
  }}
  let(:services) { [ service1, service2 ]}
  
  describe 'GET /services' do
    context 'with (UU)ID given,' do
      context 'valid and stored' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services/' + service_uuid).to_return(:body => service1.to_json)
          get '/services/'+ service_uuid
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services/' + service_uuid)).to have_been_made
        end
        
        it 'shoud return success (200)' do
          expect(last_response.status).to eq(200)
        end
        
        it 'should return only one service' do
          parsed_response = JSON.parse(last_response.body)
          expect(parsed_response['uuid']).to eq(service_uuid)
        end
      end
      
      context 'valid but not stored' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services/' + non_existent_service_uuid).to_return(status: 404)
          get '/services/'+ non_existent_service_uuid
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services/' + non_existent_service_uuid)).to have_been_made
        end
        it 'shoud return :not_found (404)' do   
          expect(last_response.status).to eq(404)
        end
      end
      context 'but invalid' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services/' + invalid_service_uuid).to_return(status: 404)
          get '/services/'+ invalid_service_uuid
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services/' + invalid_service_uuid)).not_to have_been_made
        end
        it 'shoud return :not_found (404)' do
          expect(last_response.status).to eq(404)
        end
      end
    end
    context 'without (UU)ID given' do
      context 'and no other params' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services?limit=10&offset=0').to_return(:body => services.to_json)
          get '/services'
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services')).to have_been_made
        end
        
        it 'shoud return success (200)' do
          expect(last_response.status).to eq(200)
        end
        
        it 'should return all services (as long as they are < DEFAULT_MAX_LIMIT)' do
          # DEFAULT_OFFSET
          # DEFAULT_LIMIT
          # DEFAULT_MAX_LIMIT
          parsed_response = JSON.parse(last_response.body)
          expect(parsed_response.count).to eq(2)
        end
      end
      
      context 'and limit param given (offset becomes DEFAULT_OFFSET)' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services?limit=10&offset='+GtkApi::DEFAULT_OFFSET.to_s)
            .with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
            .to_return(:body => services[0].to_json)
          get '/services?limit=1'
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services?limit=10&offset='+GtkApi::DEFAULT_OFFSET.to_s)
            .with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}))
            .to have_been_made
        end
        
        it 'shoud return success (200)' do
          expect(last_response.status).to eq(200)
        end
        
        it 'should return all services (as long as they are < DEFAULT_MAX_LIMIT)' do
          parsed_response = JSON.parse(last_response.body)
          expect(parsed_response['uuid']).to eq(services[0][:uuid])
        end
      end
      
      # only to be tested if more than DEFAULT_LINIT services could be mocked
      context 'and offset param given (limit becomes DEFAULT_LIMIT)'
        
      context 'and limit and offset param given' do
        before(:example) do
          stub_request(:get, GtkApi::settings.srvmgmt+'/services?limit=1&offset=1')
            .with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
            .to_return(:body => services[1].to_json)
          get '/services?limit=1&offset=1'
        end
        it 'should call the Service Management Service' do
          expect(a_request(:get, GtkApi::settings.srvmgmt+'/services?limit=1&offset=1')
            .with(headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'})
            .to have_been_made
        end
        
        it 'shoud return success (200)' do
          expect(last_response.status).to eq(200)
        end
        
        it 'should return all services (as long as they are < DEFAULT_MAX_LIMIT)' do
          parsed_response = JSON.parse(last_response.body)
          expect(parsed_response['uuid']).to eq(services[1][:uuid])
        end
      end
    end
  end
end
