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
  namespace '/api/v2' do
    #options '/' do
    before do
      if request.request_method == 'OPTIONS'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST,PUT'      
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
        halt 200
      end
    end

    # GET many licences
    get '/licences/?' do
      # TODO
      log_message = 'GtkApi::GET /api/v2/licences/?'
    
      logger.debug(log_message) {"entered with "+query_string}
    
      @offset ||= params['offset'] ||= DEFAULT_OFFSET 
      @limit ||= params['limit'] ||= DEFAULT_LIMIT

      licences = LicenceManagerService.find(params)
      logger.debug(log_message) {"Found licences #{licences}"}
      case licences[:status]
      when 200
        logger.debug(log_message) {"links: request_url=#{request_url}, limit=#{@limit}, offset=#{@offset}, total=#{licences[:count]}"}
        links = build_pagination_headers(url: request_url, limit: @limit.to_i, offset: @offset.to_i, total: licences[:count].to_i)
        logger.debug(log_message) {"links: #{links}"}
        headers 'Link'=> links, 'Record-Count'=> licences[:count].to_s
        status 200
        halt licences[:items].to_json
      else
        message = "No licences with #{params} were found"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end

    # GET a specific licence
    get '/licences/:uuid/?' do
      log_message = MODULE+' GET /api/v2/licences/:uuid'
      logger.debug(log_message) {"entered with #{params[:uuid]}"}
    
      if valid?(params[:uuid])
        licence = LicenceManagerService.find_by_uuid(params[:uuid])
        if licence
          logger.debug(log_message) {"leaving with #{licence}"}
          halt 200, licence.to_json
        else
          logger.debug(log_message) {"leaving with message 'Licence #{params[:uuid]} not found'"}
          json_error 404, "Licence #{params[:uuid]} not found"
        end
      else
        message = "Licence #{params[:uuid]} not valid"
        logger.debug(log_message) {"leaving with message '"+message+"'"}
        json_error 404, message
      end
    end
    
    post '/licences/?' do
      log_message = 'GtkApi::POST /licences/?'
      body = request.body.read
      
      # Don't raise exception here, return HTTP error
      #raise ArgumentError.new('Licences have to have parameters') if (body && body.empty?)
      
      
      logger.debug(log_message) {"body=#{body}"}
      # 'type_uuid', String *
      # 'service_uuid', String *
      # 'user_uuid', String *
      # 'license_uuid', String *
      # 'description', String
      # 'startingDate', DateTime
      # 'expiringDate', DateTime * 
      # 'status', String
      
      params = JSON.parse(body, symbolize_names: true)
      logger.debug(log_message) {"entered with params=#{params}"}

      licence = LicenceManagerService.create(params)
      logger.debug(log_message) {"licence=#{licence.inspect}"}
      case licence[:status]
      when 201
        logger.info(log_message) {"leaving with licence: #{licence[:items]}"}
        headers 'Location'=> LicenceManagerService.class_variable_get(:@@url)+"/licences/#{licence[:uuid]}", 'Content-Type'=> 'application/json'
        halt 201, licence.to_json
      when 400
        json_error 400, '{}', 'Unprocessable entity'
      when 422
        json_error 422, '{}', 'Unprocessable entity'
      else
        json_error 500, "Internal error while trying to create a licence with params #{params}"
      end
    end
  end
  
  namespace '/api/v2/admin/licences' do
    get '/logs/?' do
      log_message = 'GtkApi::GET /api/v2/admin/licences/logs'
      logger.debug(log_message) {'entered'}
      url = LicenceManagerService.class_variable_get(:@@url)+'/admin/logs'
      log = LicenceManagerService.get_log(url: url, log_message:log_message)
      logger.debug(log_message) {'leaving with log='+log}
      headers 'Content-Type' => 'text/plain; charset=utf8', 'Location' => '/'
      halt 200, log
    end
  end
end
