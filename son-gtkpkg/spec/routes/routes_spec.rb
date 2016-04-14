## SONATA - Gatekeeper
##
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

RSpec.describe Gtkpkg do
  #include Rack::Test::Methods
  #def app
  #  Gtkpkg # this defines the active application for this test
  #end
  
  let(:response_body) {{ 'uuid'=> "dcfb1a6c-770b-460b-bb11-3aa863f84fa0", 'descriptor_version' => "1.0", 'package_group' => "eu.sonata-nfv.package", 'package_name' => "simplest-example", 'package_version' => "0.1", 'package_maintainer' => "Michael Bredel, NEC Labs Europe"}}

  describe 'POST \'/packages\'' do
    context 'with correct parameters' do
      # curl -F "package=@simplest-example.son" localhost:5000/packages

      package_file_name = 'simplest-example.son'
      @package_file = Rack::Test::UploadedFile.new('./spec/fixtures/simplest-example.son','application/octet-stream', true)
      @package = { filename: package_file_name, type: 'application/octet-stream', name: 'package', tempfile: @package_file, #File.open('./spec/fixtures/'+package_file_name, 'rb')
        head: "Content-Disposition: form-data; name=\"package\"; filename=\"#{package_file_name}\"\r\nContent-Type: application/octet-stream\r\n"
      }
      let(:pkgmgr) {stub_request(:post, 'http://localhost:5100/packages').to_return(:status=>201, :body=>response_body, :headers=>{ 'Content-Type'=>'application/json' })}
      # .with(:headers => { 'Content-Type' => 'application/octet-stream' })
  
      before do
        stub_request(:post, 'localhost:5100/packages').to_return(:status=>201, :body=>response_body.to_json) #, :headers=>{ 'Content-Type'=>'application/json' })
        post '/packages', :package => @package #package_file
      end

      subject { last_response }
      its(:status) { is_expected.to eq 201 }

#      it 'returns the JSON related to the resource creation' do
#        expect(last_response.headers['Content-Type']).to include 'application/json'
#        parsed_body = JSON.parse(JSON.parse(last_response.body, :quirks_mode => true))
#        expect(parsed_body).to be_an_instance_of(Hash)
#        expect(parsed_body).to eq response_body
#      end

#      it 'should return a UUID' do
        # /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
#        parsed_body = JSON.parse(JSON.parse(last_response.body, :quirks_mode => true))
#        uuid = parsed_body.fetch('uuid')
#        expect(uuid).to be_an_instance_of(String)
#        expect(uuid.length).to eq 36
#      end
    end
  
    context 'with invalid parameters given' do
    end
  end

  describe 'GET /packages' do
    context 'with (UU)ID given' do      
      before do
        stub_request(:get, 'localhost:5200/packages').to_return(:status=>200, :body=>response_body.to_json, :headers=>{ 'Content-Type'=>'application/json' })
        get '/packages/dcfb1a6c-770b-460b-bb11-3aa863f84fa0'
      end
      subject { last_response }
      #its(:status) { is_expected.to eq 200 }
    end
    context 'with query parameters given' do
    end
    context 'without any query parameter given' do
    end
  end
end

# it 'saves string to the file system' do
#  string_changer = StringChanger.new
#  File.stub(:write)
#
#  string_changer.reverse_and_save('example string')
#
#  expect(File).
#    to have_received(:write).
#    with('example_file', 'gnirts elpmaxe').
#    once
#end


#    it "redirects to /play" do
#      follow_redirect!
#      last_request.path.should == '/play'
#    end
