require_relative '../spec_helper'
require 'webmock/rspec'
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'

RSpec.describe 'Package API' do
  describe 'POST /packages' do
    context 'with valid parameters given' do
      # curl -F "package=@simplest-example.son" localhost:5000/packages
  
      package_file_name = 'simplest-example.son'
      let(:response_body) {{ 'uuid'=> "dcfb1a6c-770b-460b-bb11-3aa863f84fa0", 'descriptor_version' => "1.0", 'package_group' => "eu.sonata-nfv.package", 'package_name' => "simplest-example", 
        'package_version' => "0.1", 'package_maintainer' => "Michael Bredel, NEC Labs Europe"}}
      @package = { filename: package_file_name, type: 'application/octet-stream', name: 'package', tempfile: File.read('./spec/fixtures/'+package_file_name),
        head: "Content-Disposition: form-data; name=\"package\"; filename=\"#{package_file_name}\"\r\nContent-Type: application/octet-stream\r\n"
      }
      let(:package_file) {Rack::Test::UploadedFile.new('./spec/fixtures/simplest-example.son','application/octet-stream', true)}
      let(:pkgmgr) {stub_request(:post, 'http://localhost:5100/packages').to_return(:status=>201, :body=>response_body, :headers=>{ 'Content-Type'=>'application/json' })}
      # .with(:headers => { 'Content-Type' => 'application/octet-stream' })
    
      before do
        stub_request(:any, 'localhost:5100/packages').to_return(:status=>201, :body=>response_body.to_json, :headers=>{ 'Content-Type'=>'application/json' })
        post '/packages', :package => package_file
      end
    
      after do
      
      end

      subject { last_response }
      
      its(:status) { is_expected.to eq 201 }
  
      it 'returns the JSON related to the resource creation' do
        expect(last_response.headers['Content-Type']).to include 'application/json'
        parsed_body = JSON.parse(JSON.parse(last_response.body, :quirks_mode => true))
        expect(parsed_body).to be_an_instance_of(Hash)
        expect(parsed_body).to eq response_body
      end
  
      it 'should return a UUID' do
        # /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
        parsed_body = JSON.parse(JSON.parse(last_response.body, :quirks_mode => true))
        uuid = parsed_body.fetch('uuid')
        expect(uuid).to be_an_instance_of(String)
        expect(uuid.length).to eq 36
      end
    end
    
    context 'with invalid parameters given' do
    end
  end
  
  describe 'GET /packages' do
    context 'with no (UU)ID given' do
      
    end
    
    context 'with (UU)ID given' do
      
    end
  end
end

