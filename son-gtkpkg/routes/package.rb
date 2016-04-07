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
require 'json' 
require 'pp'
require 'addressable/uri'

class Gtkpkg < Sinatra::Base

  # Receive the Java package
  post '/packages/?' do
    logger.info "GtkPkg: entered POST \"/packages\""
    
    #if params['package']['filename']
    #  filename = params['package']['filename']
    #elsif params['package'][:filename]
    #  filename = params['package'][:filename]
      #else
    #  json_error 400, 'File name not specified' unless filename
      #end
    
    #extract_dir = Package.save( filename, request.body.read)
    #Package.extract( extract_dir, filename)

    # Validate Manifest dir and file existance
    #json_error 400, 'META-INF directory not found' unless File.directory?(extract_dir + '/META-INF')
    #json_error 400, 'MANIFEST.MF file not found' unless File.file?(extract_dir + '/META-INF/MANIFEST.MF')
    # Validate Manifest fields
    #validate_manifest(YAML.load_file(extract_dir + '/META-INF/MANIFEST.MF'), files: [filename, extract_dir])

    #remove_leftover([filename, extract_dir])

    #TODO: Send package to catalog
    body =   { 
      'uuid'=> "dcfb1a6c-770b-460b-bb11-3aa863f84fa0", 
      'descriptor_version' => "1.0", 'package_group' => "eu.sonata-nfv.package", 
      'package_name' => "simplest-example", 'package_version' => "0.1", 
      'package_maintainer' => "Michael Bredel, NEC Labs Europe",
      'created_at'=> Time.now.utc,
      'updated_at'=> Time.now.utc
    }
    logger.info "GtkPkg: leaving POST \"/packages\" with package #{body.to_json}"
    
    # TODO: URL should be absolute
    halt 201, {'Location' => "/packages/#{body['uuid']}"}, body.to_json
  end
  
  get '/packages/:uuid' do
    unless params[:uuid].nil?
      logger.info "GtkPkg: entered GET \"/packages/#{params[:uuid]}\""
      package = Catalogue.find_by_uuid( params[:uuid])
      logger.info package
      if package['uuid']
        headers = {'Location'=>"#{Gtkpkg.settings.catalogues['url']}/#{package['uuid']}", 'Content-Type'=> 'application/json'}
        logger.info "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with package #{package}"
        halt 200, headers, package
      else
        logger.info "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.info "GtkApi: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
    
    
    #content_type :son
    #   send_file(file, :disposition => 'attachment', :filename => File.basename(file))
    #send_file('spec/fixtures/simplest-example.son', :disposition => 'inline') #, :type => :son)
  end

  get '/packages' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.info "GtkPkg: entered GET \"/packages/#{uri.query}\""
    
    packages = Catalogue.find( params)
    logger.info "GtkPkg: leaving GET \"/packages/#{uri.query}\" with #{packages.inspect}"
    halt 200, packages if packages
  end
end
