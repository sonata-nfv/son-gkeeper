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
require 'tempfile'
require 'pp'

class Catalogue
  class << self
    
    def find_by_uuid( uuid)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        response = RestClient.get( Gtkpkg.settings.catalogues['url']+"/#{uuid}", headers) 
        pp response
        response.body
      rescue => e
        e.inspect
        [500, '', e]
      end
      
    end
    
    def find( params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params
      pp headers
      begin
        response = RestClient.get Gtkpkg.settings.catalogues['url'], headers        
        response.body
      rescue => e
        e.inspect
        [500, '', e]
      end
    end
    
  end
end