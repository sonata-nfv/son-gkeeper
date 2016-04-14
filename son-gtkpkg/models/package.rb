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
require 'tempfile'
require 'yaml'
require 'pp'
require 'securerandom'
require 'rubygems'
require 'zip'

class Package

  DEFAULT_META_DIR = 'META-INF'
  DEFAULT_MANIFEST_FILE_NAME = 'MANIFEST.MF'
  DEFAULT_PATH = File.join(DEFAULT_META_DIR, DEFAULT_MANIFEST_FILE_NAME)
  
  def initialize(descriptor)
    pp "Package#initialize: descriptor=#{descriptor}"
    @descriptor = descriptor
    @input_folder = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))[0]
    @output_folder = File.join( 'public', 'packages', descriptor['uuid'])
    FileUtils.mkdir_p @output_folder unless File.exists? @output_folder
    @services, @functions, @docker_files = []
  end
  
  # Saves a package from its description
  def save(descriptor, filename = DEFAULT_PATH)   
    begin      
      File.open(File.join(@path, filename), 'w') {|f| YAML.dump(descriptor, f)}
    rescue => e
      e.to_json
    end
  end

  # Loads a package 'file' into its descriptor
  def load(filename = DEFAULT_PATH)
    begin
      YAML.load_file File.join(@path, filename)
    rescue => e
      e.to_json
    end
  end
  
  # Builds a package file from its descriptors, and return a handle to it
  def build()
    # Clear unwanted parameters
    [:uuid, :created_at, :updated_at].each { |k| @descriptor.delete(k) }

    meta_dir = FileUtils.mkdir(File.join(@input_folder, DEFAULT_META_DIR))[0]
    save_package_descriptor @descriptor, meta_dir
    @descriptor['package_content'].each do |p_cont|
      NService.new(@input_folder).build(p_cont) if p_cont['name'] =~ /service_descriptors/
      VFunction.new(@input_folder).build(p_cont) if p_cont['name'] =~ /function_descriptors/
      DockerFile.new(@input_folder).build(p_cont) if p_cont['name'] =~ /docker_files/
    end
    output_file = File.join(@output_folder, @descriptor['package_name']+'.son')
    FileUtils.rm output_file if File.file? output_file
    zip_it output_file
    pp  "Package.build: output_file #{output_file}"
    output_file
  end
    
  class << self
    
    def find_by_uuid(uuid)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      pp "Package#find_by_uuid(#{uuid}): headers #{headers}"
      begin
        response = RestClient.get( Gtkpkg.settings.catalogues['url']+"/packages/#{uuid}", headers) 
        pp "Package#find_by_uuid(#{uuid}): #{response}"      
        JSON.parse response.body
      rescue => e
        e.to_json
      end
    end
    
    def find(params)
      headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
      headers[:params] = params unless params.empty?
      pp "Package#find(#{params}): headers #{headers}"
      begin
        response = RestClient.get(Gtkpkg.settings.catalogues['url']+'/packages', headers)
        pp "Package#find(#{params}): #{response}"      
        JSON.parse response.body
      rescue => e
        e.to_json
      end
    end
  end
  
  private 
  
  def save_package_descriptor(descriptor, meta_dir)
    fname = File.join(meta_dir, DEFAULT_MANIFEST_FILE_NAME)
    File.open( fname, 'w') {|f| YAML.dump(descriptor, f) }
  end

  def zip_it(zipfile_name)
    entries = Dir.entries(@input_folder) - %w(. ..)
    ::Zip::File.open(zipfile_name, ::Zip::File::CREATE) do |io|
      write_entries entries, '', io
    end
    
  end
  
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_folder, zip_file_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, io, zip_file_path)
      else
        put_into_archive(disk_file_path, io, zip_file_path)
      end
    end
  end
  
  def recursively_deflate_directory(disk_file_path, io, zip_file_path)
    io.mkdir zip_file_path
    subdir = Dir.entries(disk_file_path) - %w(. ..)
    write_entries subdir, zip_file_path, io
  end

  def put_into_archive(disk_file_path, io, zip_file_path)
    io.get_output_stream(zip_file_path) do |f|
      f.puts(File.open(disk_file_path, 'rb').read)
    end
  end
end
#def extract( extract_dir, filename)
  # Extract the zipped file to a directory
#  Zip::File.open(File.join(extract_dir, filename), 'rb') do |zip_file|
    # Handle entries one by one
#    zip_file.each do |entry|
      # Extract to tmp/
#      f_path = File.join(extract_dir, entry.name)
#      entry.extract(f_path)
#    end
#  end
#end
