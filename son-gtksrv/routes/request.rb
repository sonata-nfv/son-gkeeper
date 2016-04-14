## SONATA - Gatekeeper
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
require 'json' 
require 'pp'
require 'addressable/uri'

class GtkSrv < Sinatra::Base

  get '/requests/:uuid' do
    logger.debug "GtkPkg: entered GET \"/requests/#{params[:uuid]}\""
    halt 501, "Not yet implemented"    
  end
  
  get '/requests/?' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkPkg: entered GET \"/requests/#{uri.query}\""
    
    packages = Catalogue.find(params)
    logger.debug "Gtkpkg: GET /packages: #{packages}"
    if packages && packages.is_a?(Array)
      if packages.size == 1
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, found package #{packages[0]}"
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, generating package"
        tmpdir = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))
        response = Package.new(tmpdir).build(packages[0])
        if response
          logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"Package #{packages[0]['uuid']} found and sent in file \"#{packages[0]['package_name']}\"\""
          send_file tmpdir + package['package_name']
        else
          logger.info "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\", with \"Could not create package file\"."
          json_error 400, "Could not create package file"
        end
      else
        logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"Found #{packages.size} packages\""
        halt 200, packages.to_json
      end
    else
      logger.debug "GtkPkg: leaving GET /packages/#{uri.query} with \"No package with params=#{uri.query} was found\""
      json_error 404, "No package with params=#{uri.query} was found"
    end
  end

  post '/requests/?' do
    logger.info "GtkPkg: entered POST \"/requests\""
    halt 501, "Not yet implemented"
  end
end
