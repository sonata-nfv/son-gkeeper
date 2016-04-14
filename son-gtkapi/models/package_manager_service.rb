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
require 'tempfile'

class PackageManagerService
  class << self
    
    # We're not yet using this: it allows for multiple implementations, such as Fakes (for testing)
    def implementation
      @implementation
    end
    
    def implementation=(impl)
      @implementation = impl
    end
    
    def save2(io)
      Tempfile.open('sonata_file', 'wb') do |output_stream|
        IO.copy_stream(io, output_stream)
      end
    end
    
    def save(path, params)
      FileUtils.mkdir_p(path) unless File.exists?(path)
    
      package_file_path = File.join(path, params[:package][:filename])
      File.open(package_file_path, 'wb') do |file|
        file.write params[:package][:tempfile].read
      end
      package_file_path
    end
  
    def onboard2(url, file_path)
      
      filename = file_path.split('/')[-1]
      extract_dir = FileUtils.mkdir(File.join('tmp', SecureRandom.uuid))
      # Extract the zipped file to a directory
      Zip::File.open(file_path, 'rb') do |zip_file|
        # Handle entries one by one
        zip_file.each do |entry|
          # Extract to tmp/
          pp "Extracting #{entry.name}"
          f_path = File.join(extract_dir, entry.name)
          entry.extract(f_path)
        end
      end
      { uuid: SecureRandom.uuid, descriptor_version: "1.0", package_vendor: "eu.sonata-nfv.package", 
        package_name: "simplest-example", package_version: "0.1", package_maintainer: "Michael Bredel, NEC Labs Europe"}
    end

    def onboard(url, file_path, file_name)
      #headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/octet-stream'}
      #package = { 'filename' => file_name, 'type' => 'application/octet-stream', 'name' => 'package', 'tempfile' => File.open(file_path, 'rb'),
      #  'head' => "Content-Disposition: form-data; name=\"package\"; filename=\"#{file_name}\"\r\nContent-Type: application/octet-stream\r\n"
      #}
      begin
        response = RestClient.post(url, :package => File.new(File.join(file_path, file_name,), 'rb'))
      rescue => e
        e.to_json
      end
    end
  
    def find_by_uuid(uuid)
      headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        # Get the meta-data first
        response = RestClient.get( GtkApi.settings.pkgmgmt['url']+"/#{uuid}", headers)
        filename = JSON.parse(response)['filepath']
        pp filename
        path = File.join('public','packages',uuid)
        FileUtils.mkdir_p path unless File.exists? path
        
        # Get the package it self
        package = RestClient.get( GtkApi.settings.pkgmgmt['url']+"/#{uuid}/package")
        File.open(filename, 'wb') do |f|
          f.write package
        end
        filename
      rescue => e
        e.to_json
      end
    end
    
    def find(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params
      begin
        RestClient.get GtkApi.settings.pkgmgmt['url'], headers        
      rescue => e
        e.to_json 
      end
    end
  end
end
