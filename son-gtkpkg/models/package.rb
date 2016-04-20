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
  
  def initialize(params)
    @descriptor = init_with_descriptor(params[:descriptor]) if params[:descriptor]
    @io = init_with_io(params[:io]) if params[:io]
    @services, @functions, @docker_files = []
  end
  
  # Saves a package from its description
  def save(descriptor, filename = DEFAULT_PATH)   
    begin      
      File.open(File.join(@output_folder, filename), 'w') {|f| YAML.dump(descriptor, f)}
    rescue => e
      e
    end
  end

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
  
  # Loads a package 'file' into its descriptor
  def load(filename = DEFAULT_PATH)
    begin
      YAML.load_file File.join(@path, filename)
    rescue => e
      e.to_json
    end
  end
  
  # Builds a package file from its descriptors, and returns a handle to it
  def build()
    # Clear unwanted parameters
    [:uuid, :created_at, :updated_at].each { |k| @descriptor.delete(k) }

    meta_dir = FileUtils.mkdir(File.join(@input_folder, DEFAULT_META_DIR))[0]
    save_package_descriptor @descriptor, meta_dir
    @descriptor['package_content'].each do |p_cont|
      pp "Package.build: p_cont=#{p_cont}"
      NService.new(@input_folder).build(p_cont) if p_cont['name'] =~ /service_descriptors/
      VFunction.new(@input_folder).build(p_cont) if p_cont['name'] =~ /function_descriptors/
      # DockerFile.new(@input_folder).build(p_cont) if p_cont['name'] =~ /docker_files/
    end
    output_file = File.join(@output_folder, @descriptor['package_name']+'.son')
    
    # Cleans things up before generating
    FileUtils.rm output_file if File.file? output_file
    zip_it output_file
    pp  "Package.build: output_file #{output_file}"
    output_file
  end

  # Unbuilds a package file from its file, and returns a descriptor to it
  def unbuild()
    files = unzip_it @io
    @descriptor ={}
    files.each do |file|
      splited = file.split('/')
      file_name = splited[-1]
      path = splited.first splited.size-1
      pp "Package.unbuild: path=#{path} (file_name = #{file_name})"
      if path =~ /service_descriptors/
        service = NService.new(path)
        pp "Package.unbuild: service=#{service}"
        @descriptor << service.unbuild(file_name)
        pp "Package.unbuild: @descriptor=#{@descriptor}" 
      end
      @descriptor << VFunction.new(path).unbuild(file_name) if path =~ /function_descriptors/
      # DockerFile.new(@input_folder).unbuild(path) if file_name =~ /docker_files/
    end
    pp  "Package.unbuild: @descriptor #{@descriptor}"
    @descriptor = {"descriptor_version"=>"1.0", "vendor"=>"eu.sonata-nfv.service-descriptor", "name"=>"sonata-demo", "version"=>"0.2", "author"=>"Michael Bredel, NEC Labs Europe", "description"=>"\"The network service descriptor for the SONATA demo,\n comprising iperf, a firewall, and tcpump.\"\n", "network_functions"=>[{"vnf_id"=>"vnf_firewall", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"firewall-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_iperf", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"iperf-vnf", "vnf_version"=>"0.1"}, {"vnf_id"=>"vnf_tcpdump", "vnf_vendor"=>"eu.sonata-nfv", "vnf_name"=>"tcpdump-vnf", "vnf_version"=>"0.1"}], "connection_points"=>[{"id"=>"ns:mgmt", "type"=>"interface"}, {"id"=>"ns:input", "type"=>"interface"}, {"id"=>"ns:output", "type"=>"interface"}], "virtual_links"=>[{"id"=>"mgmt", "connectivity_type"=>"E-LAN", "connection_points_reference"=>["vnf_iperf:mgmt", "vnf_firewall:mgmt", "vnf_tcpdump:mgmt", "ns:mgmt"]}, {"id"=>"input-2-iperf", "connectivity_type"=>"E-Line", "connection_points_reference"=>["ns:input", "vnf_iperf:input"]}, {"id"=>"iperf-2-firewall", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_iperf:output", "vns_firewall:input"]}, {"id"=>"firewall-2-tcpdump", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vns_firewall:output", "vnf_tcpdump:input"]}, {"id"=>"tcpdump-2-output", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_firewall:output", "ns:output"]}], "forwarding_graphs"=>[{"fg_id"=>"ns:fg01", "number_of_endpoints"=>2, "number_of_virtual_links"=>4, "constituent_vnfs"=>["vnf_iperf", "vnf_firewall", "vnf_tcpdump"], "network_forwarding_paths"=>[{"fp_id"=>"ns:fg01:fp01", "policy"=>"none", "connection_points"=>[{"connection_point_ref"=>"ns:input", "position"=>1}, {"connection_point_ref"=>"vnf_iperf:input", "position"=>2}, {"connection_point_ref"=>"vnf_iperf:output", "position"=>3}, {"connection_point_ref"=>"vnf_firewall:input", "position"=>4}, {"connection_point_ref"=>"vnf_firewall:output", "position"=>5}, {"connection_point_ref"=>"vnf_tcpdump:input", "position"=>6}, {"connection_point_ref"=>"vnf_tcpdump:output", "position"=>7}, {"connection_point_ref"=>"ns:output", "position"=>8}]}]}]}
    @descriptor['uuid'] = SecureRandom.uuid
    @descriptor
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
  
  def init_with_descriptor(descriptor)
    pp "Package#initialize: descriptor=#{descriptor}"
    @descriptor = descriptor
    @input_folder = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))[0]
    @output_folder = File.join( 'public', 'packages', @descriptor['uuid'])
    FileUtils.mkdir_p @output_folder unless File.exists? @output_folder
  end
  
  def init_with_io(io)
    pp "Package#initialize: io=#{io}"
    @io = io
  end

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
  
  #def extract( extract_dir, filename)
  def unzip_it(io)
    files = []
    pp "Package.unzip_it: io = #{io}"
    io.rewind
    unzip_folder = FileUtils.mkdir(File.join('tmp', SecureRandom.hex))
    # Extract the zipped file to a directory
    Zip::InputStream.open(io) do |io| #StringIO.new(input)) do |io|
      while entry = io.get_next_entry
        files << entry.name if valid_entry_name? entry.name
      end
    end
    pp "Package.unzip_it: files = #{files}"
    files
  end
  
  def valid_entry_name?(name)
    (name =~ /function_descriptors/ || name =~ /service_descriptors/) && name.split('/').size > 1
  end
end
