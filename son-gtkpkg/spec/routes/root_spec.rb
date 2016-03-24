require_relative '../spec_helper'
require 'webmock'

describe 'Test Root Path access' do
  before do
    stub_request(:get, 'localhost:4567').to_return(:body => File.new('./config/api.yml'), :status => 200)
    get '/'
  end

  it 'is successful' do
    expect(last_response.status).to eq 200
  end
end
