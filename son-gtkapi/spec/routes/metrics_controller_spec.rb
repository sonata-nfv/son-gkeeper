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
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'
require 'base64'

RSpec.describe GtkApi, type: :controller do
  include Rack::Test::Methods
  def app() GtkApi end

  # .../functions/instances/:instance_uuid/asynch-mon-data?metric=vm_cpu_perc&since=…&until=…
  describe 'GET /api/v2/functions/instances/:instance_uuid/asynch-mon-data/?' do
    let(:known_instance_uuid) {SecureRandom.uuid}
    let(:unknown_instance_uuid) {SecureRandom.uuid}
    let(:since_date) {'2017-04-11T11:31:31Z'}
    let(:until_date) {'2017-04-11T11:31:31Z'}
    let(:single_metric_name) {'vm_cpu_perc'}
    let(:single_metric_list) {[single_metric_name]}
    let(:spied_function) {spy('function', uuid: known_function_uuid, instances: [known_instance_uuid])}
    let(:spied_metric) {spy('metric', name: single_metric_list, instances: [known_instance_uuid])}
    let(:token) {'abc'}

    before do
      allow(User).to receive(:authorized?).with(token: token, params: {path: '/functions/instances', method: 'GET'}).and_return(true)
      allow(Metric).to receive(:counter_kpi)
    end

    context 'should return Ok (200)' do
      it 'when all that is needed is given' do
        allow(Metric).to receive(:validate_and_create).with(single_metric_list).and_return(spied_metric)
        allow(Metric).to receive(:find_by_name).with(single_metric_list.first).and_return(spied_metric)
        get '/api/v2/functions/instances/'+known_instance_uuid+'/asynch-mon-data?metrics='+single_metric_name+'&since='+since_date+'&until='+until_date, {}, {'HTTP_AUTHORIZATION' => 'Bearer '+token}
        expect(last_response.status).to eq(200)
      end
    end
    
    context 'should return Not Found (404)' do
      #it 'with unknown instance' do        
      #  allow(spied_function).to receive(:load_instances).and_return(spied_function.instances)
      #  allow(FunctionManagerService).to receive(:find_by_uuid!).with(known_function_uuid).and_return(spied_function)
      #  get '/api/v2/functions/'+known_function_uuid+'/instances/'+unknown_instance_uuid+'/asynch-mon-data?metrics=vm_cpu_perc&since='+since_date+'&until='+until_date
      #  expect(last_response.status).to eq(404)
      #end
    end
    
    context 'should return Unprocessable Entity (400)' do
      before(:each) do
        allow(Metric).to receive(:find_by_name).with(single_metric_list).and_return(spied_metric)
        allow(Metric).to receive(:validate_and_create).with(single_metric_list).and_return(spied_metric)
      end
        
      it 'without list of metrics ' do
        get '/api/v2/functions/instances/'+known_instance_uuid+'/asynch-mon-data?since='+since_date+'&until='+until_date , {}, {'HTTP_AUTHORIZATION' => 'Bearer '+token}
        expect(last_response.status).to eq(400)
      end
      context 'with missing limits:' do
        let (:fixed_url) {'/api/v2/functions/instances/'+known_instance_uuid+'/asynch-mon-data?metrics='+single_metric_name}
        it 'without start date' do
          get fixed_url+'&until='+until_date, {}, {'HTTP_AUTHORIZATION' => 'Bearer '+token}
          expect(last_response.status).to eq(400)
        end
        it 'without end date' do
          get fixed_url+'&since='+since_date, {}, {'HTTP_AUTHORIZATION' => 'Bearer '+token}
          expect(last_response.status).to eq(400)
        end
        it 'without any date' do
          get fixed_url, {}, {'HTTP_AUTHORIZATION' => 'Bearer '+token}
          expect(last_response.status).to eq(400)
        end
      end
    end
  end

  # …/functions/instances/:instance_uuid/synch-mon-data?metrics=vm_cpu_perc&for=<number of seconds>
  describe 'GET /api/v2/functions/instances/:instance_uuid/synch-mon-data/?' do
    context 'with all that is needed'
    context 'with unknown function'
    context 'with unknown instance'
    context 'with missing list of metrics'
  end
end
