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
# encoding: utf-8
require 'addressable/uri'

class GtkApi < Sinatra::Base
  
  # GET many packages
  get '/services' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info "GtkApi: entered GET /services/#{uri.query}"
    
    # TODO: deal with offset and limit
    #offset = params[:offset]
    #limit = params[:limit]   
    
    services = ServiceManagerService.find(params)
    logger.info "GtkApi: leaving GET /services/#{uri.query} with #{services}"
    halt 200, services.to_json if services
  end
  
  # GET a specific service
  get '/services/:uuid/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered GET /services/#{params[:uuid]}"
      json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
      
      package_file_path = ServiceManagerService.find_by_uuid( params[:uuid])
      logger.info package_file_path
      if package_file_path
        logger.info "GtkApi: leaving GET /packages/#{params[:uuid]} with package #{package_file_path}"
        send_file package_file_path
      else
        logger.info "GtkApi: leaving GET /packages/#{params[:uuid]} with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.info "GtkApi: leaving GET /packages/#{params[:uuid]} with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
end