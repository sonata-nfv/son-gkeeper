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
  
  def initialize(path, output_folder)
    @path = path
    @output_folder = output_folder
    @services, @functions, @docker_files = []
    pp "Gtkpkg::Package#initialize: @path="+@path
  end
  
  # Saves a package from its description
  def save(descriptor, filename = DEFAULT_PATH)   
    begin      
      File.open(File.join(@path, filename), 'w') {|f| YAML.dump(descriptor, f)} #f.write descriptor.to_yaml }
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
  def build(descriptor)
    pp "Gtkpkg::Package.build(#{descriptor}): entered"
    
    # Clear unwanted parameters
    [:uuid, :created_at, :updated_at].each { |k| descriptor.delete(k) }
    meta_dir = FileUtils.mkdir(File.join(@path, DEFAULT_META_DIR))[0]
    pp "Gtkpkg.build: meta_dir=#{meta_dir}"
    save_package_descriptor descriptor, meta_dir
    pp "Gtkpkg.build: going through descriptor['package_content']: #{descriptor['package_content']}"
    descriptor['package_content'].each do |p_cont|
      pp "Gtkpkg.build: content to work with: #{p_cont}"
      pp "Gtkpkg.build: name=#{p_cont['name']}"
      chunk = p_cont['name'] =~ /service_descriptors/ ? "matches service_descriptors" : "doesn't match with service_descriptors"
      pp "Gtkpkg.build: content "+chunk
      pp "Gtkpkg.build: #{p_cont['name'].split('/')[1]}"
      if p_cont['name'] =~ /service_descriptors/
        pp "Gtkpkg.build: NService#new(#{@path}).build(#{p_cont})) to be called"
        NService.new(@path).build(p_cont)
        pp "Gtkpkg.build: NService#new(#{@path}).build(#{p_cont}) called"
      end
      pp "Gtkpkg.build: content " + (p_cont['name'] =~ /function_descriptors/ ? "matches function_descriptors" : "doesn't match with function_descriptors")
      VFunction.new(@path).build(p_cont) if p_cont['name'] =~ /function_descriptors/
      pp "Gtkpkg.build: content " + (p_cont['name'] =~ /docker_files/? "matches docker_files" : "doesn't match with docker_files")
      DockerFile.new(@path).build(p_cont) if p_cont['name'] =~ /docker_files/
    end
    pp "Gtkpkg.build: zipping to file #{descriptor['package_name']}.son in folder #{@path}"
    output_file = File.join(@output_folder, descriptor['package_name']+'.son')
    FileUtils.rm output_file if File.file? output_file
    zip_it output_file

    pp "Gtkpkg::Package.build: saved in folder #{@path}"
    @path
  end
    
  class << self  
    def save2( filename, io)
      # Save posted file
    
      file = Tempfile.new(['foo', '.jpg'])
      begin
      #   ...do something with file...
      ensure
         file.close
         file.unlink   # deletes the temp file
      end
      save_dir = File.join('tmp', SecureRandom.hex)
      FileUtils.mkdir_p(save_dir) unless File.exists? save_dir
  
      pp "Saving file #{filename} in #{save_dir}"
      File.open(File.join( save_dir, filename), 'wb') do |f|
        f.write(io)
      end
      save_dir
    end
    
    def extract( extract_dir, filename)
      # Extract the zipped file to a directory
      Zip::File.open(File.join(extract_dir, filename), 'rb') do |zip_file|
        # Handle entries one by one
        zip_file.each do |entry|
          # Extract to tmp/
          pp "Extracting #{entry.name}"
          f_path = File.join(extract_dir, entry.name)
          entry.extract(f_path)
        end
      end
    end
  end
  
  private 
  
  def save_package_descriptor(descriptor, meta_dir)
    fname = File.join(meta_dir, DEFAULT_MANIFEST_FILE_NAME)
    File.open( fname, 'w') {|f| YAML.dump(descriptor, f) }
    pp "Gtkpkg::Package.save_package_descriptor: saved #{descriptor} in folder #{meta_dir}"
  end

  def zip_it(zipfile_name)
    entries = Dir.entries(@path) - %w(. ..)

    ::Zip::File.open(zipfile_name, ::Zip::File::CREATE) do |io|
      write_entries entries, '', io
    end
    
  end
  
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@path, zip_file_path)
      puts "Deflating #{disk_file_path}"

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