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
require 'webmock/rspec'
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'

RSpec.describe GtkApi, type: :controller do
  include Rack::Test::Methods
  def app() GtkApi end

  describe 'POST /api/v2/sessions' do
    let(:auth_info) {{name: 'Unknown', password: 'None'}}
    let(:user_spied) {spy('user', uuid: SecureRandom.uuid, session: 'session')}
    let(:user_info) {{uuid: user_spied.uuid, password: auth_info[:password]}}
    context 'with user name and password given,' do
      context 'and user is authenticated,' do
        before(:each) do
          allow(user_spied).to receive(:authenticate!).and_return(user_spied.session)
          allow(User).to receive(:find_by_name).with(auth_info[:name]).and_return(user_spied)
          post '/api/v2/sessions/', auth_info.to_json
        end
        it 'returns Ok (200)' do
          expect(last_response.status).to eq(200)
        end
        it 'calls user.authenticate!' do
          expect(user_spied).to have_received(:authenticate!)
        end
      end
      context 'but user is not authenticated,' do
        before(:each) do
          allow(user_spied).to receive(:authenticate!).and_return(nil)
          allow(User).to receive(:find_by_name).with(auth_info[:name]).and_return(user_spied)
          post '/api/v2/sessions/', auth_info.to_json
        end
        it 'calls User.authenticate!' do
          expect(user_spied).to have_received(:authenticate!)
        end
        it 'returns Unauthorized (401)' do
          expect(last_response.status).to eq(401)
        end
      end

    end
    context 'without' do
      it 'user name given returns Unprocessable Entity (400)' do
        post '/api/v2/sessions/', {name: '', password: 'None'}.to_json
        expect(last_response.status).to eq(400)
      end
      it 'password given returns Unprocessable Entity (400)' do
        post '/api/v2/sessions/', {name: 'Unknown', password: ''}.to_json
        expect(last_response.status).to eq(400)
      end
    end
  end
  
  describe 'DELETE /api/v2/sessions/:user_name' do
    context 'with user name given' do
      let(:auth_info) {{name: 'Unknown', password: 'None'}}
      let(:user_spied) {spy('user', uuid: SecureRandom.uuid, session: 'session', name: auth_info[:name])}
      let(:user_info) {{uuid: user_spied.uuid, password: auth_info[:password]}}
      context 'and found' do
        context 'and is successfully deleted' do
          before(:each) do
            allow(user_spied).to receive(:logout!)
            allow(User).to receive(:find_by_name).with(auth_info[:name]).and_return(user_spied)
            delete '/api/v2/sessions/'+auth_info[:name]
          end
          it 'returns Ok (200)' do
            expect(last_response.status).to eq(200)
          end
          it 'calls user.logout!' do
            expect(user_spied).to have_received(:logout!)
          end
        end
      end
      it 'but not found, returns Not Found (404)' do
        allow(User).to receive(:find_by_name).with(auth_info[:name]).and_return(nil)
        delete '/api/v2/sessions/'+auth_info[:name]
        expect(last_response.status).to eq(404)
      end
    end
    it 'without user name given' do
      post '/api/v2/sessions/', {name: '', password: 'None'}.to_json
      expect(last_response.status).to eq(400)
    end
  end
end
