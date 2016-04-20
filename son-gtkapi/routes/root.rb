# encoding: utf-8
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
class GtkApi < Sinatra::Base
  
  DEFAULT_OFFSET = "0"
  DEFAULT_LIMIT = "10"
  DEFAULT_MAX_LIMIT = "100"

  # Root
  get '/' do
    headers "Content-Type" => "text/plain; charset=utf8"
    api = open('./config/api.yml')
    halt 200, {'Location' => '/'}, api.read.to_s
  end
end