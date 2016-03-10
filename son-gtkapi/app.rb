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
enable :sessions
config_file 'config/services.yml'

# https://github.com/achiu/rack-parser
use Rack::Parser, :content_types => {
  'application/json' => Proc.new { |body| ::MultiJson.decode body }
}

get '/' do
  #send_file './config/api.yml'
  #erb './config/api.yml'
  api = YAML.load_file './config/api.yml'
  halt 200, {'Location' => '/'}, api.to_s
end

# https://github.com/sinatra/sinatra-recipes/blob/ecc597b3725bb9eb7ac9e30a89f72b0d9b0c9af5/middleware/rack_parser.md
post '/orders' do
  order = Order.from_hash( params['order'] )
  order.process
  # ....
end

post '/messages' do
  message = Message.from_hash( ::MultiJson.decode(request.body) )
  message.save
  halt 201, {'Location' => "/messages/#{message.id}"}, ''
end



def require_logged_in
    redirect('/sessions/new') unless is_authenticated?
end

def is_authenticated?
    return !!session[:user_id]
end

get '/' do
  erb :login
end

get '/sessions/new' do
  erb :login
end

post '/sessions' do
  session[:user_id] = params["user_id"]
  redirect('/secrets')
end

get '/secrets' do
  require_logged_in
  erb :secrets
end
