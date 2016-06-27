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
# encoding: utf-8
# spec/spec_helper.rb
require 'rack/test'
require 'rspec'
require 'webmock/rspec'

ENV['RACK_ENV'] ||= 'test'

$: << File.expand_path('../..', __FILE__)
require 'gtk_vim'

def app
  GtkSrv
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.mock_with :rspec
  config.include WebMock::API
end

# WebMock.disable_net_connect!(allow_localhost: true)
WebMock.allow_net_connect!
