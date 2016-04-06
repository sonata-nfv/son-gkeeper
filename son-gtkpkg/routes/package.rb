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

class Gtkpkg < Sinatra::Base

  # Receive the Java package
  post '/packages/?' do
    logger.info params.inspect
    
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
      'package_maintainer' => "Michael Bredel, NEC Labs Europe"
  }
    # TODO: URL should be absolute
    halt 201, {'Location' => "/packages/#{body['uuid']}"}, body.to_json
  end
  
  get '/packages/:uuid' do
    pp params['uuid']
    json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
    
    # TODO: grab package info from Catalogue
    
    #content_type :son
    #   send_file(file, :disposition => 'attachment', :filename => File.basename(file))
    send_file('spec/fixtures/simplest-example.son', :disposition => 'inline') #, :type => :son)
  end

end
