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
require_relative '../spec_helper'
require 'webmock/rspec'
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'

RSpec.describe GtkApi do
  describe 'GET /services' do
    context 'with (UU)ID given' do      
      before do
        stub_request(:get, 'localhost:5100/packages').to_return(:status=>200, :body=>response_body.to_json, :headers=>{ 'Content-Type'=>'application/json' })
        get '/services'
      end
    
      subject { last_response }
      #its(:status) { is_expected.to eq 200 }

    end
    context 'without (UU)ID given' do
    end
  end
end
