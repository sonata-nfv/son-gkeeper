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
require File.expand_path '../../spec_helper.rb', __FILE__
#require_relative '../spec_helper'
require 'webmock/rspec'
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'

RSpec.describe GtkApi do
  include Rack::Test::Methods
  
  def app
    GtkApi # this defines the active application for this test
  end

  describe 'GET "/"' do
    before do
      stub_request(:get, 'localhost:5000').to_return(:body => File.new('./config/api.yml'), :status => 200)
      get '/'
    end

    subject { last_response }
    its(:status) { is_expected.to eq 200 }
  end
  
  describe 'GET "/api-doc"' do
    let(:doc) {  File.new('./views/api_doc.erb')}

    before do
      stub_request(:get, 'localhost:5000/api-doc').to_return(body: File.new('./views/api_doc.erb'), status: 200)
      get '/api-doc'
    end

    subject { last_response }
    its(:status) { is_expected.to eq 200 }
    its(:body) { is_expected.to eq File.new('./views/api_doc.erb').read }    
  end
end
