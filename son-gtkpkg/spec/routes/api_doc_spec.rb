require_relative '../spec_helper'
require 'webmock'

RSpec.describe 'Test /api-doc Path access' do
  let(:doc) {  File.new('./views/api_doc.erb')}

  before do
    stub_request(:get, 'localhost:4567/api-doc').to_return(body: File.new('./views/api_doc.erb'), status: 200)
    get '/api-doc'
  end

  it 'is successful' do
    expect(last_response.status).to eq 200
  end
  
  it 'returns the doc' do
    expect(last_response.body).to eq File.new('./views/api_doc.erb').read
  end
end

