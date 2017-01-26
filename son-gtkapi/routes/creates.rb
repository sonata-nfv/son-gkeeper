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
    
  namespace '/api/v2' do
    post '/licence-types/?' do
      log_message = 'GtkApi::POST /licence-types/?'
      params = JSON.parse(request.body.read)
      logger.info(log_message) {"entered with params=#{params}"}
      raise ArgumentError.new('Licence type has to have a description') unless params && params['description']
      raise ArgumentError.new('Licence type has to have a duration') unless params && params['duration']
    
      # description, duration, status
      licence_type = LicenceManagerService.create_type(params)
      logger.debug(log_message) {"licence_type=#{licence_type.inspect}"}
      if licence_type
        logger.info(log_message) {"leaving with licence_type: #{licence_type}"}
        headers 'Location'=> LicenceManagerService.url+"/licence-types/#{licence_type[:uuid]}", 'Content-Type'=> 'application/json'
        halt 201, licence_type.to_json
      else
        json_error 400, 'Licence type not created'
      end
    end
    
    post '/licences/?' do
      log_message = 'GtkApi::POST /licences/?'
      body = request.body.read
      raise ArgumentError.new('Licences have to have parameters') if (body && body.empty?)
      logger.debug(log_message) {"body=#{body}"}
      # 'type_uuid', String *
      # 'service_uuid', String *
      # 'user_uuid', String *
      # 'license_uuid', String *
      # 'description', String
      # 'startingDate', DateTime
      # 'expiringDate', DateTime * 
      # 'status', String
      
      params = JSON.parse(body)
      logger.debug(log_message) {"entered with params=#{params}"}
    
      # description, duration, status
      licence = LicenceManagerService.create_licence(params)
      logger.debug(log_message) {"licence=#{licence.inspect}"}
      if licence
        if licence.is_a?(Hash) && (licence[:uuid] || licence['uuid'])
          logger.info(log_message) {"leaving with licence: #{licence}"}
          headers 'Location'=> LicenceManagerService.url+"/licences/#{licence[:uuid]}", 'Content-Type'=> 'application/json'
          halt 201, licence.to_json
        else
          json_error 400, 'No UUID given to licence'
        end
      else
        json_error 400, 'Licence not created'
      end
    end
  end
end
