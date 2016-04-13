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

class Gtkpkg < Sinatra::Base

  # Receive the Java package
  #post '/uploads' do
  #  puts "Params: " + params.inspect
  #  puts "Headers: " + headers.inspect
  #  if params[:file]
  #    filename = params[:file][:filename]
  #    file = params[:file][:tempfile]

  #    File.open(File.join('files/p2', filename), 'wb') do |f|
  #      f.write file.read
  #    end
  #    puts 'Upload successful'
  #  else
  #    puts 'You have to choose a file'
  #  end
  #end

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
      if package && package.is_a?(Hash) && package['uuid']
        logger.info "GtkPkg: in GET /packages/#{params[:uuid]}, found package #{package}"
        tmpdir = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))[0]
        logger.info "GtkPkg: in GET /packages/#{params[:uuid]}, tmpdir=#{tmpdir}"
        logger.info "GtkPkg: in GET /packages/#{params[:uuid]}, generating package"
        output_dir = File.join( 'public', 'packages', params[:uuid])
        FileUtils.mkdir_p output_dir unless File.exists? output_dir
        response = Package.new(tmpdir, output_dir).build(package)    
        if response
          logger.info "GtkPkg: leaving GET /packages/#{params[:uuid]} with package found and sent in file \""+tmpdir+"/#{package['package_name']}.son\"\""
          halt 200, { 'filepath'=>File.join('public', 'packages', params[:uuid], package['package_name']+'.son')}.to_json
        else
          logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\", with \"Could not create package file\"."
          json_error 400, "Could not create package file"
        end
      else
        logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with \"No package with UUID=#{params[:uuid]} was found\""
        json_error 400, "No package with UUID=#{params[:uuid]} was found"
      end
    end
    logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end
  
  get '/packages/:uuid/packages?' do
    unless params[:uuid].nil?
      logger.info "GtkPkg: entered GET \"/packages/#{params[:uuid]}/package\""
      entries = Dir.entries(File.join('public','packages',params[:uuid])) - %w(. ..)
      logger.info "GtkPkg: entries are #{entries}"
      send_file entries[0] if entries.size
      logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}/package\" with \"No package file found for package #{params[:uuid]}\""
      json_error 400, "No package file found for package #{params[:uuid]}"
    end
    logger.error "GtkPkg: leaving GET \"/packages/#{params[:uuid]}/package\" with \"No package UUID specified\""
    json_error 400, 'No package UUID specified'
  end

  get '/packages' do
    uri = Addressable::URI.new
    uri.query_values = params
    logger.debug "GtkPkg: entered GET \"/packages/#{uri.query}\""
    
    packages = Catalogue.find(params)
    logger.debug "Gtkpkg: GET /packages: #{packages}"
    if packages && packages.is_a?(Array)
      if packages.size == 1
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, found package #{packages[0]}"
        logger.debug "GtkPkg: in GET /packages/#{uri.query}, generating package"
        tmpdir = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))
        response = Package.new(tmpdir).build(packages[0])        
        #headers = { 'Location'=>"#{Gtkpkg.settings.catalogues['url']}/#{packages[0]['uuid']}", 'Accept' => 'application/octet-stream'}
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
end
