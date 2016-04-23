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

  # buffer = StringIO.new
  # buffer.set_encoding('ASCII-8BIT')
  
  # POST of packages
  post '/packages/?' do
    logger.info "GtkApi: entered POST /packages with params = #{params}"
    
    unless params[:package].nil?
      if params[:package][:tempfile]
        package = PackageManagerService.create(params)
        if package
          if package.is_a?(Hash) && (package[:uuid] || package['uuid'])
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
        json_error 400, 'Temp file name not provided'
      end
    end
    json_error 400, 'No package file specified'
  end

  # GET a specific package
  get '/packages/:uuid/?' do
    unless params[:uuid].nil?
      logger.debug "GtkApi: entered GET \"/packages/#{params[:uuid]}\""
      json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
      
      package_file_path = PackageManagerService.find_by_uuid( params[:uuid])
      logger.debug "GtkApi: package_file_path #{package_file_path}"
      if package_file_path
        logger.debug "GtkApi: leaving GET /packages/#{params[:uuid]} with package #{package_file_path}"
        send_file package_file_path
      else
        logger.debug "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 404, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.debug "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
  
  # GET potentially many packages
  get '/packages' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkApi: entered GET /packages?#{uri.query}"
    
    @offset ||= params[:offset] ||= DEFAULT_OFFSET
    @limit ||= params[:limit] ||= DEFAULT_LIMIT
    
    packages = PackageManagerService.find(params)
    logger.debug "GtkApi: leaving GET /packages?#{uri.query} with #{packages}"
    halt 200, packages if packages
  end
  
  # PUT 
  put '/packages/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered PUT /packages/#{params[:uuid]}"
      logger.info "GtkApi: leaving PUT /packages/#{params[:uuid]} with \"Not implemented yet\""
    end
    json_error 501, "Not implemented yet"
  end
  
  # DELETE
  delete '/packages/:uuid/?' do
    unless params[:uuid].nil?
      logger.info "GtkApi: entered DELETE \"/packages/#{params[:uuid]}\""
      logger.info "GtkApi: leaving DELETE \"/packages/#{params[:uuid]}\" with \"Not implemented yet\""
    end
    json_error 501, "Not implemented yet"
  end
end

#get '/downloads/:filename' do
#  puts "Params: " + params.inspect
#  puts "Headers: " + headers.inspect
#  url = 'http://localhost:5678/downloads/'
#  puts "Getting file "+params[:filename]+" from "+url

#  response = RestClient.get(url+params[:filename])
#  puts "Saving file on '/files/p1'..."
#  File.open(File.join('files/p1', params[:filename]), 'wb') do |f|
#    f.write response #.body.read
#  end
#  send_file 'files/p1/'+params[:filename]
#end


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
