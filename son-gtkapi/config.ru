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

# https://github.com/sinatra/sinatra-recipes/blob/ecc597b3725bb9eb7ac9e30a89f72b0d9b0c9af5/middleware/rack_parser.md
#use Rack::Parser, :content_types => {
#  'application/json' => Proc.new { |body| ::MultiJson.decode body }
#}

root = ::File.dirname(__FILE__)
require ::File.join(root, 'gtk_api')

run GtkApi.new