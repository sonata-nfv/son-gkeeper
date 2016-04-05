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
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/octet-stream'}
      package = { 'filename' => file_name, 'type' => 'application/octet-stream', 'name' => 'package', 'tempfile' => File.open(file_path, 'rb'),
        'head' => "Content-Disposition: form-data; name=\"package\"; filename=\"#{file_name}\"\r\nContent-Type: application/octet-stream\r\n"
      }
      begin
        RestClient.post( url, {package: package}, headers) 
      rescue => e
        e.inspect
        [500, '', e]
      end
    end
  
    def find_by_id( url, uuid)
      pp uuid, uuid.class
      headers = { accept: 'application/json', content_type: 'application/json'}
      #package = { filename: file_name, type: 'application/octet-stream', name: 'package', tempfile: File.new(file_path, 'rb').read,
      #  head: "Content-Disposition: form-data; name=\"package\"; filename=\"#{file_name}\"\r\nContent-Type: application/octet-stream\r\n"
      #}
      begin
  #      package = RestClient.get( url+'/'+uuid, headers) 
        package = {
          'uuid'=> uuid, #"dcfb1a6c-770b-460b-bb11-3aa863f84fa0",
          'descriptor_version' => "1.0",
          'package_group' => "eu.sonata-nfv.package",
          'package_name' => "simplest-example",
          'package_version' => "0.1", 'package_maintainer' => "Michael Bredel, NEC Labs Europe"}
      rescue => e
        e.inspect
        [500, '', e]
      end
    end
  end
end
