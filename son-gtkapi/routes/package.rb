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
# encoding: utf-8
require 'addressable/uri'

class GtkApi < Sinatra::Base

  DEFAULT_OFFSET = 0
  DEFAULT_LIMIT = 5
  DEFAULT_MAX_LIMIT = 100  

  # buffer = StringIO.new
  # buffer.set_encoding('ASCII-8BIT')
  
  # POST of packages
  post '/packages/?' do
    logger.info "GtkApi: entered POST \"/packages/\""

    #content_type 'application/octet-stream'
    
    #filename = PackageManagerService.save2(request.body.read)
    unless params[:package].nil?    
      package_file_path = PackageManagerService.save( settings.files, params)
      if package_file_path
        logger.info "package_file_path: #{package_file_path}"
        package = PackageManagerService.onboard2( settings.pkgmgmt['url'], package_file_path)
        if package
          if package.kind_of?(Hash) && package[:uuid]
            logger.info "package: #{package}"
            headers = {'location'=> "#{settings.pkgmgmt['url']}/#{package[:uuid]}", 'Content-Type'=> 'application/json'}
            halt 201, headers, package.to_json
          else
            json_error 400, 'No UUID given to package'
          end
        else
          json_error 400, 'Package not created'
        end
      else
        json_error 400, 'Package with invalid content'
      end
    end
    json_error 400, 'No package file specified'
  end

  # GET a specific package
  get '/packages/:uuid/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered GET \"/packages/#{params[:uuid]}\""
      json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
      
      package = PackageManagerService.find_by_uuid( params[:uuid])
      logger.info package
      if package['uuid']
        headers = {'Location'=> "#{GtkApi.settings.pkgmgmt['url']}/#{package['uuid']}", 'Content-Type'=> 'application/json'}
        logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with package #{package}"
        halt 200, headers, package
      else
        logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
  
  # GET potentially many packages
  get '/packages' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info "GtkApi: entered GET \"/packages/#{uri.query}\""
    
    # TODO: deal with offset and limit
    #offset = params[:offset]
    #limit = params[:limit]   
    
    packages = PackageManagerService.find( params)
    logger.info "GtkApi: leaving GET \"/packages/#{uri.query}\" with #{params.inspect}"
    halt 200, packages if packages
  end
  
  # PUT 
  put '/packages/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered PUT \"/packages/#{params[:uuid]}\""
      logger.info "GtkApi: leaving PUT \"/packages/#{params[:uuid]}\" with \"Not implemented yet\""
    end
    json_error 501, "Not implemented yet"
  end
  
  # DELETE
  delete '/packages/:uuid/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered DELETE \"/packages/#{params[:uuid]}\""
      logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"Not implemented yet\""
    end
    json_error 501, "Not implemented yet"
  end
end

  
#  file = "#{params[:splat].first}.#{params[:splat].last}"
#  path = "<path to files directory>/#{file}"
  #
#  if File.exists? path
#  send_file(
#    path, :disposition => 'attachment', : filename => file
#  )
#  else
#      halt 404, "File not found"
#  end
