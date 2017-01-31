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

RSpec.describe ServiceManagerService, type: :model do
  def app() GtkApi end
  let(:service_uuid) {SecureRandom.uuid}
  let(:unknown_service_uuid) {SecureRandom.uuid}
  let(:service_to_be_created_1) {{name:'name', version:'0.1', vendor:'vendor'}}
  let(:created_service_1) {service_to_be_created_1.merge({uuid: service_uuid})}
  let(:service_to_be_created_2) {{name:'name', version:'0.2', vendor:'vendor'}}
  let(:created_service_2) {service_to_be_created_2.merge({uuid: service_uuid})}
  let(:all_services) { {'count': 2, 'items':[ created_service_1, created_service_2 ]}}
  #let(:curl_easy) {instance_double("Curl::Easy", head_str: 'HTTP/1.1 200')} 
  describe '#find_services' do
    it 'with default parameters should return two services' do
      resp = OpenStruct.new(head_str: 'HTTP/1.1 200', body: all_services.to_json)      
      allow(Curl).to receive(:get).with('http://localhost:5300/services?limit=10&offset=0').and_return(resp) 
      services = ServiceManagerService.find_services({'limit': 10, 'offset': 0})
      expect(services).to eq({'count': 2, 'items': all_services})      
    end
    it 'with only default offset parameter (0) should return two services' do
      resp = OpenStruct.new(head_str: 'HTTP/1.1 200', body: all_services.to_json)      
      allow(Curl).to receive(:get).with('http://localhost:5300/services?offset=0').and_return(resp) 
      services = ServiceManagerService.find_services({'offset': 0})
      expect(services).to eq({'count': 2, 'items': all_services})      
    end
    #it 'with parameter limit 1 should return one service' do
      #resp = OpenStruct.new(head_str: 'HTTP/1.1 200', body: all_services.to_json)      
      #allow(Curl).to receive(:get).with('http://localhost:5300/services?offset=0').and_return(resp) 
      #resp = OpenStruct.new(head_str: 'HTTP/1.1 200', body: all_services[0].to_json)      
      #allow(Curl).to receive(:get).with('http://localhost:5300/services?limit=1&offset=0').and_return(resp) 
      #services = ServiceManagerService.find_services({'limit': 1, 'offset': 0})
      #expect(services).to eq({'count': 2, 'items': all_services[0]})      
      #end
  end
  describe '#find_service_by_uuid' do
    context 'with valid UUID' do
      it 'should find a service with a known UUID' do
        resp = OpenStruct.new(head_str: 'HTTP/1.1 200', body: all_services[0].to_json)      
        allow(Curl).to receive(:get).with('http://localhost:5300/services/'+service_uuid).and_return(resp) 
        service = ServiceManagerService.find_service_by_uuid(uuid: service_uuid)
        expect(service).to eq(all_services[0])      
      end
      it 'should not find a service with an unknown UUID' do
        resp = OpenStruct.new(head_str: 'HTTP/1.1 404', body: {}.to_json)      
        allow(Curl).to receive(:get).with('http://localhost:5300/services/'+unknown_service_uuid).and_return(resp) 
        service = ServiceManagerService.find_service_by_uuid(uuid: unknown_service_uuid)
        expect(service).to eq({})      
      end
    end
    context 'with an invalid UUID' do
    end
  end
  describe '#find_requests' do
  end
  describe '#find_requests_by_uuid' do
    context 'with valid' do
      it 'and known UUID should find and return the request'
      it 'and unknown UUID should return an empty list'
    end
    context 'with invalid UUID' do
      it 'should return an error'
    end
  end
  describe '#create_service_intantiation_request' do
    it 'should POST /catalogues/packages to catalogues'
  end
  describe '#create_service_update_request' do
    it 'should POST /catalogues/packages to catalogues'
  end
end