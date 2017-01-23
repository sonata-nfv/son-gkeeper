##
## Copyright (c) 2015 SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## ALL RIGHTS RESERVED.
## 
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
## 
##     http://www.apache.org/licenses/LICENSE-2.0
## 
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
## 
## Neither the name of the SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote 
## products derived from this software without specific prior written 
## permission.
## 
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through 
## the Horizon 2020 and 5G-PPP programmes. The authors would like to 
## acknowledge the contributions of their colleagues of the SONATA 
## partner consortium (www.sonata-nfv.eu).
# encoding: utf-8
require 'sinatra/namespace'
class GtkApi < Sinatra::Base

  register Sinatra::Namespace
  helpers GtkApiHelper
  
  MESSAGE = 'GtkApi::POST /api/v2'
  
    post '/api/v2/licence-types/?' do
      log_message = MESSAGE + '/licence-types/?'
      params = JSON.parse(request.body.read)
      logger.info(log_message) {"entered with params=#{params}"}
      raise ArgumentError.new('Licence type has to have a description') unless params && params['description']
    
      # description, duration, status
      licence_type = LicenceManagerService.create_type(params)
      logger.debug(log_message) {"licence_type=#{licence_type.inspect}"}
      if licence_type
        if licence_type.is_a?(Hash) && (licence_type[:uuid] || licence_type['uuid'])
          logger.info(log_message) {"leaving with licence_type: #{licence_type}"}
          headers 'Location'=> LicenceManagerService.url+"/licence-types/#{licence_type[:uuid]}", 'Content-Type'=> 'application/json'
          halt 201, licence_type.to_json
        else
          json_error 400, 'No UUID given to licence type'
        end
      else
        json_error 400, 'Licence type not created'
      end
    end
    
    namespace '/api/v2/' do
    post '/licences/?' do
      log_message = MESSAGE + '/licences/?'
      logger.info(log_message) {"entered with params=#{params}"}
    end
  end
end