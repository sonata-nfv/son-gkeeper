# spec/app_spec.rb
require File.expand_path '../spec_helper.rb', __FILE__

describe "SONATA SP's Gatekeeper API" do
  it "should allow accessing the home route" do
    get '/'
    expect(last_response).to be_ok
  end
end
