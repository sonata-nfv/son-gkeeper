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

  DEFAULT_OFFSET = 0
  DEFAULT_LIMIT = 5
  DEFAULT_MAX_LIMIT = 100
  
  # GET many packages
  get '/services' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info "GtkApi: entered GET \"/packages/#{uri.query}\""
    
    # TODO: deal with offset and limit
    #offset = params[:offset]
    #limit = params[:limit]   
    
    #packages = PackageManagerService.find(params)
    #logger.info "GtkApi: leaving GET \"/packages/#{uri.query}\" with #{packages}"
    #halt 200, packages if packages
  end
  
  # GET a specific service
  get '/services/:uuid/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered GET \"/packages/#{params[:uuid]}\""
      json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
      
      package_file_path = PackageManagerService.find_by_uuid( params[:uuid])
      logger.info package_file_path
      if package_file_path
        logger.info "GtkApi: leaving GET /packages/#{params[:uuid]} with package #{package_file_path}"
        send_file package_file_path
      else
        logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
end
