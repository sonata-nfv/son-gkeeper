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

  describe 'POST /api/v2/users' do
    let(:user_basic_info) {{
      enabled: true, totp: false, emailVerified: false,
      firstName: "Un", lastName: "Known",
      requiredActions: [], federatedIdentities: [],
      attributes: {developer: ["true"], customer: ["false"], admin: ["false"]}, 
      realmRoles: [], clientRoles: {}, groups: ["developers"]}
    }
    let(:user_info) {user_basic_info.merge({username: "Unknown", email: "user.sample@email.com.br", credentials: [ {type: "password", value: "1234"} ]})}
    let(:user_with_no_name) {user_basic_info.merge({username: "", email: "user.sample@email.com.br", credentials: [ {type: "password", value: "1234"} ]})}
    it 'without user name given returns Unprocessable Entity (400)' do
      post '/api/v2/users/', user_with_no_name.to_json
      expect(last_response.status).to eq(400)
    end

    context 'with user name ' do
      let(:user_with_no_password) {user_basic_info.merge({username: "Unknown", email: "user.sample@email.com.br", credentials: [ {type: "password", value: ""} ]})}
      let(:user_with_no_email) {user_basic_info.merge({username: "Unknown", email: "", credentials: [ {type: "password", value: "1234"} ]})}
      let(:created_user) { user_info.merge({uuid:SecureRandom.uuid})}
      it 'given, but no password, returns Unprocessable Entity (400)' do
        post '/api/v2/users/', user_with_no_password.to_json
        expect(last_response.status).to eq(400)
      end
      it 'given, but no email, returns Unprocessable Entity (400)' do
        post '/api/v2/users/', user_with_no_email.to_json
        expect(last_response.status).to eq(400)
      end
      it 'and password given returns Ok (201)' do
        user = double('User', uuid: created_user[:uuid])
        allow(User).to receive(:create).with(user_info).and_return(user)
        post '/api/v2/users/', user_info.to_json
        expect(last_response.status).to eq(201)
      end
    end
  end
end
