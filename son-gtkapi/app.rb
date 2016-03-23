## SONATA - Gatekeeper
##
## Copyright 2015-2017 Portugal Telecom Inovação/Altice Labs
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
require 'sinatra'
require 'sinatra/config_file'
require 'json'
require 'yaml'
require 'rack/parser'

set :root, File.dirname(__FILE__)
set :bind, '0.0.0.0'
set :public_folder, 'public'
use Rack::Session::Cookie, :key => 'rack.session', :domain => 'foo.com', :path => '/', :expire_after => 2592000, :secret => '$0nata'
enable :logging

config_file 'config/services.yml'

# https://github.com/achiu/rack-parser
use Rack::Parser, :content_types => { 'application/json' => Proc.new { |body| ::MultiJson.decode body } }

get '/' do
  headers "Content-Type" => "text/plain; charset=utf8"
  api = open('./config/api.yml')
  halt 200, {'Location' => '/'}, api.read.to_s
end

get '/api-doc' do
  #redirect '/swagger/index.html' 
  erb :api_doc
end

#get '/foo/bar/?' do
#  "Hello World"
#end
#The route matches "/foo/bar" and "/foo/bar/".