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
  
  def initialize(url: nil, logger: nil, params: nil)
    @url = url
    @logger = logger
    @package, @service = {}
    @functions = []
    create_from_descriptor(params[:descriptor]) if params[:descriptor]
    create_from_io(params[:io]) if params[:io]
  end
  
  # Saves a package from its description
  #def save(descriptor, filename = DEFAULT_PATH)   
  #  begin      
  #    File.open(File.join(@output_folder, filename), 'w') {|f| YAML.dump(descriptor, f)}
  #  rescue => e
  #    e
  #  end
  #end
  
  # Loads a package 'file' into its descriptor
  #def load(filename = DEFAULT_PATH)
  #  begin
  #    YAML.load_file File.join(@path, filename)
  #  rescue => e
  #    e.to_json
  #  end
  #end
  
  # Builds a package file from its descriptors, and returns a handle to it
  def build()
    @descriptor = clear_unwanted_parameters @descriptor
    meta_dir = FileUtils.mkdir(File.join(@input_folder, DEFAULT_META_DIR))[0]
    save_package_descriptor meta_dir
    @logger.debug "\nPackage.build: @descriptor=#{@descriptor}"
    @logger.debug "\nPackage.build: @descriptor[:package_content]=#{@descriptor[:package_content]}"
    @descriptor[:package_content].each do |p_cont|
      @logger.debug "Package.build: p_cont=#{p_cont}"
      NService.new( @url, @logger, @input_folder).build(p_cont) if p_cont['name'] =~ /service_descriptors/
      VFunction.new( @url, @logger, @input_folder).build(p_cont) if p_cont['name'] =~ /function_descriptors/
      
      # No Dockerfiles treated at the moment
      # DockerFile.new(@input_folder).build(p_cont) if p_cont['name'] =~ /docker_files/
    end
    output_file = File.join(@output_folder, @descriptor[:package_name]+'.son')
    
    # Cleans things up before generating
    FileUtils.rm output_file if File.file? output_file
    zip_it output_file
    @logger.debug  "Package.build: output_file #{output_file}"
    output_file
  end

  # Unbuilds a package file from its file, and returns a descriptor to it
  def unbuild()
    files = unzip_it @io
    @service = {}
    @functions = []
    files.each do |file|
      splited = file.split('/')
      file_name = splited[-1]
      path = File.join(splited.first splited.size-1)
      @logger.debug "Package.unbuild: path=#{path}, file_name = #{file_name}"
      @descriptor = YAML.load_file(file) if path =~ /META-INF/
      @service = NService.new( @url, @logger).unbuild(file) if path =~ /service_descriptors/      
      @functions << VFunction.new( @url, @logger).unbuild(file) if path =~ /function_descriptors/
      # DockerFile.new(@input_folder).unbuild(path) if file_name =~ /docker_files/
      #pp  "Package.unbuild: @descriptor #{@descriptor}"
      #pp  "Package.unbuild: @service #{@service}"
      #pp  "Package.unbuild: @functions #{@functions}"
    end
    #pp  "Package.unbuild: @descriptor #{@descriptor}"
    
    if valid? @descriptor
      return @package if store_all
      @logger.error "Package.unbuild: couldn't store package based on descriptor (#{@descriptor})"
    else
      @logger.error "Package.unbuild: invalid descriptor (#{@descriptor})"
    end
    {}
  end

  def self.find_by_uuid(uuid)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = uuid
    @logger.debug "Package#find_by_uuid(#{uuid}): headers #{headers}"
    begin
      response = RestClient.get(@url+"/packages/#{uuid}", headers) 
      @logger.debug "Package#find_by_uuid(#{uuid}): #{response}"      
      JSON.parse response.body
    rescue => e
      e.to_json
    end
  end
  
  def self.find(params)
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params unless params.empty?
    @logger.debug "Package#find(#{params}): headers #{headers}"
    begin
      response = RestClient.get(@url+'/packages', headers)
      @logger.debug "Package#find(#{params}): #{response}"      
      JSON.parse response.body
    rescue => e
      e.to_json
    end
  end
  
  private 
  
  def create_from_descriptor(descriptor)
    @logger.debug "Package#initialize: descriptor=#{descriptor}"
    @descriptor = descriptor
    @input_folder = File.join('tmp', SecureRandom.hex)
    FileUtils.mkdir_p @input_folder unless File.exists? @input_folder
    @output_folder = File.join( 'public', 'packages', @descriptor['uuid'])
    FileUtils.mkdir_p @output_folder unless File.exists? @output_folder
  end
  
  def create_from_io(io)
    @logger.debug "Package#initialize: io=#{io}"
    @io = io
  end
  
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

  def save_package_descriptor(meta_dir)
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
    io.rewind
    unzip_folder = FileUtils.mkdir_p(File.join('tmp', SecureRandom.hex))
    
    # Extract the zipped file into a directory
    Zip::InputStream.open(io) do |zip_file|
      @logger.debug "Package.unzip_it: zip_file = #{zip_file}"
      while (entry = zip_file.get_next_entry)
        @logger.debug "Package.unzip_it: entry.name = #{entry.name}"
        if valid_entry_name? entry.name
          disk_file_path = File.join(unzip_folder, entry.name) 
          if entry.name.split('/').size == 1
            FileUtils.mkdir_p disk_file_path unless File.exists? disk_file_path
            @logger.debug "Package.unzip_it: disk_file_path"+disk_file_path+" is a directory"
          else
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
  
  def store_to_catalogue
    @logger.debug "\nPackage.store_to_catalogue("+@descriptor.to_s+")"
    
    begin
      response = RestClient.post( @url+'/packages', @descriptor.to_json, content_type: :json, accept: :json)
      package = JSON.parse response
    rescue => e
        puts e.response
        nil
    end
    @logger.debug "Package.store_to_catalogue: package=#{package} for response=#{response}"
    if package && package['uuid']
      @logger.debug "Package.store_to_catalogue: #{response}"
      package
    else
      @logger.debug "Package.store_to_catalogue: failled to store #{@descriptor} with #{response}"
      nil
    end
  end

  def store_all
    if @package = store_to_catalogue
      if @service
        service = NService.store_to_catalogue(@service)
        
        @logger.debug "Package.unbuild: stored service #{service}"
        # TODO: what if storing a service goes wrong?
        # rollback!
      end
      if @functions.size
        @functions.each do |vf|
          @logger.debug "Package.unbuild: vf = #{vf}"
          function = VFunction.store_to_catalogue(vf)
          if function
            @logger.debug "Package.unbuild: stored function #{function}"
            # TODO: rollback if failled
          end
        end
      end
      @logger.debug "Package.unbuild: stored package #{@package}"
      @package
    else
      @logger.debug "Package.unbuild: failled to store #{@descriptor}"
      {}
    end
  end
end
