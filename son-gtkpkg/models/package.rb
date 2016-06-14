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
  
  attr_accessor :descriptor
  
  def initialize(catalogue: nil, logger: nil, params: nil)
    @logger = logger
    @service = {}
    @functions = []
    @catalogue = catalogue
    @url = @catalogue.url
    if params[:descriptor]
      @descriptor = params[:descriptor]
      @input_folder = File.join('tmp', SecureRandom.hex)
      FileUtils.mkdir_p @input_folder unless File.exists? @input_folder
      @output_folder = File.join( 'public', 'packages', @descriptor['uuid'])
      FileUtils.mkdir_p @output_folder unless File.exists? @output_folder
    elsif params[:io]
      @package_file = params[:io]
    else
      @logger.error 'Package.initialize: either @descriptor or @io must be given'
    end 
  end
    
  # Builds a package file from its descriptors, and returns a handle to it
  def to_file()
    @descriptor = clear_unwanted_parameters @descriptor
    save_package_descriptor()
    @logger.debug "Package.to_file: @descriptor=#{@descriptor}"
    @logger.debug "Package.to_file: @descriptor[:package_content]=#{@descriptor[:package_content]}"
    @descriptor[:package_content].each do |p_cont|
      @logger.debug "Package.to_file: p_cont=#{p_cont}"
      if p_cont['name'] =~ /service_descriptors/
        @service = NService.new(settings.services_catalogue, @logger, @input_folder)
        @service.to_file(p_cont)
      end
      if p_cont['name'] =~ /function_descriptors/
        function = VFunction.new(settings.functions_catalogue, @logger, @input_folder)
        function.to_file(p_cont)
        @functions << function
      end
    end
    output_file = File.join(@output_folder, @descriptor[:name]+'.son')
    
    # Cleans things up before generating
    FileUtils.rm output_file if File.file? output_file
    zip_it output_file
    @logger.debug "Package.to_file: output_file #{output_file}"
    output_file
  end

  # Unbuilds a package file from its file, and returns a descriptor to it
  def from_file()
    files = unzip_it @package_file
    #@service = {}
    @functions = []
    files.each do |file|
      splited = file.split('/')
      file_name = splited[-1]
      path = File.join(splited.first splited.size-1)
      @logger.debug('Package.from_file') { "path=#{path}, file_name = #{file_name}"}
      if path =~ /META-INF/
        @descriptor = YAML.load_file(file) 
        @logger.debug('Package.from_file') { "@descriptor=#{@descriptor}"}
      end
      if path =~ /service_descriptors/
        @service = NService.new(GtkPkg.settings.services_catalogue, @logger, nil)
        @logger.debug('Package.from_file') { "service=#{@service}"}
        @service.from_file(file)
      end
      if path =~ /function_descriptors/
        function = VFunction.new(GtkPkg.settings.functions_catalogue, @logger, nil)
        function.from_file(file)
        @logger.debug('Package.from_file') { "function=#{function}"}
        @functions << function
      end
    end
    @logger.debug('Package.from_file') { "@descriptor is #{@descriptor}"}
    @logger.debug('Package.from_file') { "@service is #{@service}"}
    @logger.debug('Package.from_file') { "@functions is #{@functions}"}
    
    if valid? @descriptor
      stored_descriptor = store_all()
      if stored_descriptor
        @logger.debug('Package.from_file') { "stored package based on descriptor=#{stored_descriptor}"}
        stored_descriptor
      else
        @logger.error('Package.from_file') { "could not store package based on descriptor=#{stored_descriptor}"}
        nil
      end     
    else
      @logger.error('Package.from_file') { "invalid descriptor (#{stored_descriptor})"}
      nil
    end
  end

  def self.find_by_uuid(uuid, logger)
    logger.debug "Package#find_by_uuid: #{uuid}"
    package = @catalogue.find_by_uuid(uuid)
    logger.debug "Package#find_by_uuid: #{package}"
    package
  end
  
  def self.find(params, logger)
    logger.debug "Package#find: #{params}"
    packages = @catalogue.find(params)
    logger.debug "Package#find: #{packages}"
    packages
  end
  
  private
  
  def keyed_hash(hash)
    @logger.debug "Package.keyed_hash hash=#{hash}"
    #Hash[hash.map{|(k,v)| v.is_a?(Hash) ? [k.to_sym,keyed_hash(v)] : [k.to_sym,v]}]
    Hash[hash.map{|(k,v)| [k.to_sym,v]}]
  end
  
  def clear_unwanted_parameters(hash)
    @logger.debug "Package.clear_unwanted_parameters hash=#{hash}"
    keyed_hash = keyed_hash(hash)
    [:uuid, :created_at, :updated_at].each { |k| keyed_hash.delete(k) }
    @logger.debug "Package.clear_unwanted_parameters keyed_hash=#{keyed_hash}"
    keyed_hash
  end

  def save_package_descriptor()
    meta_dir = FileUtils.mkdir(File.join(@input_folder, DEFAULT_META_DIR))[0]
    fname = File.join(meta_dir, DEFAULT_MANIFEST_FILE_NAME)
    File.open( fname, 'w') {|f| YAML.dump(@descriptor, f) }
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
    io.get_output_stream(zip_file_path) { |f| f.puts(File.open(disk_file_path, 'rb').read) }
  end
  
  def unzip_it(io)    
    files = []
    @logger.debug "Package.unzip_it: io = #{io.inspect}"
    #@logger.debug "Package.unzip_it: io is " + (io.closed? ? "closed" : "opened")
    #io.rewind
    #@logger.debug "Package.unzip_it: io is " + (io.closed? ? "closed" : "opened")
    unzip_folder = FileUtils.mkdir_p(File.join('tmp', SecureRandom.hex))
    
    # Extract the zipped file into a directory
    Zip::InputStream.open(io) do |zip_file|
      @logger.debug "Package.unzip_it: zip_file = #{zip_file}"
      while (entry = zip_file.get_next_entry)
        @logger.debug "Package.unzip_it: entry.name = #{entry.name}"
        if valid_entry_name? entry.name
          disk_file_path = File.join(unzip_folder, entry.name) 
          entry_name_splited = entry.name.split('/')          
          if entry_name_splited.size == 1
            # just a folder
            FileUtils.mkdir_p disk_file_path unless File.exists? disk_file_path
            @logger.debug "Package.unzip_it: disk_file_path"+disk_file_path+" is a directory"
          else
            # a file, and maybe a folder
            file_name = entry_name_splited.pop
            file_folders = File.join(unzip_folder, entry_name_splited)
            FileUtils.mkdir_p file_folders unless File.exists? file_folders
            @logger.debug "Package.unzip_it: disk_file_path is a file "+disk_file_path
            File.open(disk_file_path, 'w') { |f| f.write entry.get_input_stream.read}
            files << disk_file_path
          end
        end
      end
    end
    @logger.debug "Package.unzip_it: files = #{files}"
    files
  end
  
  def valid_entry_name?(name)
    (name =~ /function_descriptors/ || name =~ /service_descriptors/ || name =~ /META-INF/)
  end
  
  def valid?(descriptor)
    true # TODO: validate the descriptor here
  end
  
  def package_store()
    @logger.debug('Package.store') {"descriptor "+@descriptor.to_s}
    
    begin
      response = RestClient.post( @url, @descriptor.to_json, content_type: :json, accept: :json)
      @logger.debug('Package.store') {"response is "+response.to_s}
      saved_descriptor = JSON.parse response
      if saved_descriptor && saved_descriptor['uuid']
        @logger.debug('Package.store') {"saved_descriptor is "+saved_descriptor.to_s}
        saved_descriptor
      else
        @logger.debug('Package.store') {"failled to store #{@descriptor} with #{response}"}
        nil
      end
    rescue => e
      @logger.error('Package.store') {"exception in storing package: "+e.response}
      # Check if this was because a duplicate package
      # {"error":"ERROR: Duplicated Package Name, Vendor and Version"}
      if e.response['error'] =~ /Duplicated Package Name, Vendor and Version/
        begin
          saved_descriptor = @catalogue.find({vendor: @descriptor['vendor'], name: @descriptor['name'], version: @descriptor['version']})
          @logger.debug('Package.store') {"saved_descriptor is "+saved_descriptor.to_s}
          if saved_descriptor && saved_descriptor['uuid']
            @logger.debug('Package.store') {"saved_descriptor is "+saved_descriptor.to_s}
            saved_descriptor
          else
            @logger.error('Package.store') {"failled to find #{@descriptor}"}
            nil
          end
        rescue => e
          @logger.error('Package.store') {"exception in finding duplicate package: "+e.response}
          nil
        end
      else
        nil
      end
    end
  end

  def store_all
    @logger.debug('Package.store_all') {"@package is #{@package}"}
    @logger.debug('Package.store_all') {"@service is #{@service}"}
    @logger.debug('Package.store_all') {"@functions is #{@functions}"}
    saved_descriptor=package_store()
    if saved_descriptor
      if @service
        @logger.debug "Package.store_all: service is #{@service}"
        stored_service = @service.store()
        if stored_service
          @logger.debug "Package.store_all: stored service #{stored_service}"
        else
          # TODO: what if storing a service goes wrong?
          # rollback!
          @logger.debug "Package.store_all: service and package rollback should happen here"
        end
      end
      if @functions.size
        @functions.each do |vf|
          @logger.debug "Package.store_all: vf = #{vf}"
          function = vf.store()
          if function
            @logger.debug "Package.store_all: stored function #{function}"
            # TODO: rollback if failled
          else
            @logger.debug "Package.store_all: function, service and package rollback should happen here"
          end
        end
      end
      @logger.debug "Package.store_all: stored package #{saved_descriptor}"
      saved_descriptor
    else
      @logger.debug "Package.store_all: failled to store package with descriptor=#{@descriptor}"
      {}
    end
  end
end
