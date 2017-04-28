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
    # expect(@object).to be_a Shirt

  describe 'POST /api/v2/users' do
    let(:user_basic_info) {{
      firstName: "Un", lastName: "Known"
      }}
    let(:user_info) {user_basic_info.merge({username: "Unknown", email: "un@known.com", password: "1234", user_type: "developer"})}
    let(:created_user) {{
      username: "Unknown",
      uuid: SecureRandom.uuid
    }}
    let(:user_with_no_name) {user_basic_info.merge({username: "", email: "un@known.com", password: "1234", user_type: "developer"})}

    before(:each) do
      allow(User).to receive(:counter_kpi)
    end
    
    it 'without user name given returns Unprocessable Entity (400)' do
      post '/api/v2/users/', user_with_no_name.to_json
      expect(last_response.status).to eq(400)
    end

    context 'with user name ' do
      let(:user_with_no_password) {user_basic_info.merge({username: "Unknown", email: "user.sample@email.com.br", password: ""} )}
      let(:user_with_no_email) {user_basic_info.merge({username: "Unknown", email: "", password: "1234"})}
      let(:user_with_no_type) {user_basic_info.merge({username: "Unknown", email: "un@known.com", password: "1234", user_type: ""})}
      it 'given, but no password, returns Unprocessable Entity (400)' do
        post '/api/v2/users/', user_with_no_password.to_json
        expect(last_response.status).to eq(400)
      end
      it 'given, but no email, returns Unprocessable Entity (400)' do
        post '/api/v2/users/', user_with_no_email.to_json
        expect(last_response.status).to eq(400)
      end
      it 'given, but no user type, returns Unprocessable Entity (400)' do
        post '/api/v2/users/', user_with_no_type.to_json
        expect(last_response.status).to eq(400)
      end
      context 'password and user type given' do
        before(:each) do
          user = double('User', uuid: created_user[:uuid], username: created_user[:username])
          allow(User).to receive(:create).with(user_info).and_return(user)
          post '/api/v2/users/', user_info.to_json
        end
        it 'returns Ok (201)' do
          expect(last_response.status).to eq(201)
        end
        it 'calls User.create' do
          expect(User).to have_received(:create)
        end
        it 'returns user name and id' do
          expect(last_response.body).to eq(created_user.to_json)
        end
      end
      
    end
  end
end
