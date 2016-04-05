# encoding: utf-8
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
class GtkApi < Sinatra::Application

  # buffer = StringIO.new
  # buffer.set_encoding('ASCII-8BIT')
  
  # POST of packages
  post '/packages/?' do
    logger.info params
    
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
      logger.info "Package UUID = #{params[:uuid]}"
      package = PackageManagerService.find_by_id( settings.pkgmgmt['url'], params[:uuid])
      if package['uuid']
        headers = {'location'=> "#{settings.pkgmgmt['url']}/#{package['uuid']}", 'content-type'=> 'application/json'}
        halt 200, headers, package.to_json
      else
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
      
    end
    json_error 400, 'No package UUID specified'
    
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
  end
end
