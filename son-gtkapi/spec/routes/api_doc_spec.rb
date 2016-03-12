require_relative '../spec_helper'
require 'webmock'

describe 'Test /api-doc Path access' do
  before do
    stub_request(:get, 'localhost:4567/api-doc').to_return(:body => File.new('./public/swagger/index.html'), :status => 200)
    get '/'
  end

  it 'is successful' do
    expect(last_response.status).to eq 200
  end
end

