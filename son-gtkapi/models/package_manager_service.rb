##
## Copyright (c) 2015 SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## ALL RIGHTS RESERVED.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Neither the name of the SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote
## products derived from this software without specific prior written
## permission.
##
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the SONATA
## partner consortium (www.sonata-nfv.eu).
# encoding: utf-8
require 'tempfile'
require './models/manager_service.rb'

class PackageManagerService < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name

  def self.url
    @@url
  end

  def self.config(url:)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered with url='+url}
    raise ArgumentError.new('PackageManagerService can not be configured with nil or empty url') if (url.nil? || url.empty?)
    @@url = url
    @@catalogue_url = ENV[GtkApi.services['catalogue']['environment']] || GtkApi.services['catalogue']['url']
    GtkApi.logger.debug(method) {'@@catalogue_url='+@@catalogue_url}
  end

  def self.create(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with params #{params}"}
    uri = @@url+'/packages'
    raise ArgumentError.new('PackageManagerService can not be created without a user') unless params.key?(:user)
    user_params = params.delete(:user)
    user = User.find_by_name(user_params[:username])
    if user
      if user.authenticated?(user_params[:secret])
        GtkApi.logger.debug(method) {"User #{user_params[:username]} authenticated"}
        if user.authorized?(user_params)
          GtkApi.logger.debug(method) {"User #{user_params[:username]} authorized"}
          begin
            # from http://www.rubydoc.info/gems/rest-client/1.6.7/frames#Result_handling
            GtkApi.logger.debug(method) {"POSTing to "+uri+ " with params #{params}"}
            RestClient.post(uri, params){ |response, request, result, &block|
              GtkApi.logger.debug(method) {"response=#{response.inspect}"}
              case response.code
              when 201
                { status: 201, count: 1, data: JSON.parse(response.body, :symbolize_names => true), message: 'Created'}
              when 409
                { status: 409, count: 0, data: JSON.parse(response.body, :symbolize_names => true), message: 'Conflict'}
              when 400
                { status: 400, count: 0, data: {}, message: "Bad Request: #{params}"}
              else
                { status: response.code, count: 0, data: {}, message: 'Unexpected code'}
              end
            }
          rescue  => e #RestClient::Conflict
            GtkApi.logger.error(method) {"Error during processing: #{$!}"}
            GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
            { status: 500, count: 0, data: {}, message: e.backtrace.join("\n\t")}
          end
        else
          GtkApi.logger.debug(method) {"user #{params[:user][:name]} not authorized"}
          { status: 403, count: 0, data: {}, message: 'Forbidden: user '+params[:user][:name]+' could not be authorized'}
        end
      else
        GtkApi.logger.debug(method) {"user #{params[:user][:name]} not authenticated"}
        { status: 401, count: 0, data: {}, message: 'Unauthorized: user '+params[:user][:name]+' could not be authenticated'}
      end
    else
      GtkApi.logger.debug(method) {"user #{params[:user][:name]} not found"}
      { status: 404, count: 0, data: {}, message: 'User '+params[:user][:name]+' not found'}
    end
  end
  
  def self.find_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
    begin
      response = RestClient.get(@@url+"/packages/#{uuid}", headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      JSON.parse response, symbolize_names: true
    rescue => e
      e.to_json
    end
  end

  def self.find_package_file_name(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered with uuid='+uuid}
    headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
    begin
      response = RestClient.get(@@url+"/son-packages/#{uuid}", headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      if response.code == 200
        JSON.parse(response, symbolize_names: true)[:grid_fs_name]
      else
        ""
      end
    rescue => e
      e.to_json
    end
  end

  def self.find(params)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    headers[:params] = params
    begin
      response = RestClient.get(@@url+'/packages', headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      JSON.parse response, symbolize_names: true
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
  def self.download(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    raise ArgumentError.new('Package can not be downloaded if uuid is not given') if uuid.nil?
    
    GtkApi.logger.debug(method) {'entered with uuid='+uuid}
    
    # TODO: validate user permission
    # TODO: validate throttle
    
    #package_file_meta_data = self.find_package_file_meta_data_by_uuid(uuid)
    #GtkApi.logger.debug(method) {"package_file_meta_data=#{package_file_meta_data}"}
    #raise 'No package file meta-data found with package file uuid='+uuid if package_file_meta_data.empty?
    
    file_name = self.save_package_file(uuid) #package_file_meta_data)
    GtkApi.logger.debug(method) {"file_name=#{file_name}"}
    raise "Package file with file_name=#{file_name} failled to be saved" if (file_name.nil? || file_name.empty?)
    file_name
  end
  
  def self.find_package_file_meta_data_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered with uuid='+uuid}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    begin
      response = RestClient.get(@@catalogue_url+"/son-packages/#{uuid}", headers)
      GtkApi.logger.debug(method) {"response.code=#{response.code}"}
      if response.code == 200
        JSON.parse(response, symbolize_names: true)
      else
        {}
      end
    rescue => e
      e.to_json
    end
  end
  
  def self.save_package_file(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {"entered with package_file_meta_data=#{uuid}"}
    
    # Get data
    url = URI(@@catalogue_url)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(@@catalogue_url+"/son-packages/#{uuid}")
    # These fields are mandatory
    request["content-type"] = 'application/zip'
    request["content-disposition"] = 'attachment; filename=<filename.son>'
    response = http.request(request)
    GtkApi.logger.debug("Catalogue response.code: #{response.code}")
    case response.code
    when '200'
      data = response.read_body
      
      # Save temporary file
      tmp_dir = File.join(GtkApi.root, 'tmp')
      FileUtils.mkdir(tmp_dir) unless File.exists?(tmp_dir)
      package_file_name = uuid+'-'+'filename.son' #package_file_meta_data[:uuid]+'-'+package_file_meta_data[:grid_fs_name]
      package_file_path = File.join(tmp_dir, package_file_name)
      File.open(package_file_path, 'w') { |file| file.write(data) }
      # pass back the name
      package_file_path
    else
      nil
    end
  end
    
  def self.delete(uuid)
    method = LOG_MESSAGE + "##{__method__}"
    GtkApi.logger.debug(method) {'entered'}
    headers = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
    begin
      response = RestClient.delete(@@url+'/packages/'+uuid, headers)
      GtkApi.logger.debug(method) {"response #{response}"}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
end
