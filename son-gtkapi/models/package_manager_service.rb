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
    
    def create(params)
      pp "PackageManagerService#create: params=#{params}"
      tmpfile = params[:package][:tempfile]
      response = RestClient.post(GtkApi.settings.pkgmgmt['url']+'/packages', params) #:file => File.open(tmpfile, 'rb').read)
      pp "PackageManagerService#create: response.class=#{response.class}"
      pp "PackageManagerService#create: response=#{response}"
      JSON.parse response
    end    
  
    def find_by_uuid(uuid)
      headers = { 'Accept'=> '*/*', 'Content-Type'=>'application/json'}
      headers[:params] = uuid
      begin
        # Get the meta-data first
        response = RestClient.get( GtkApi.settings.pkgmgmt['url']+"/packages/#{uuid}", headers)
        filename = JSON.parse(response)['filepath']
        pp filename
        path = File.join('public','packages',uuid)
        FileUtils.mkdir_p path unless File.exists? path
        
        # Get the package it self
        package = RestClient.get( GtkApi.settings.pkgmgmt['url']+"/packages/#{uuid}/package")
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
        response = RestClient.get(GtkApi.settings.pkgmgmt['url']+'/packages', headers)
        pp "PackageManagerService#find: response #{response}"
        response
      rescue => e
        e.to_json 
      end
    end
    
    def get_log
      pp "PackageManagerService#get_log: url "+GtkApi.settings.pkgmgmt['url']+'/admin/logs'
      RestClient.get(GtkApi.settings.pkgmgmt['url']+'/admin/logs')      
    end
  end
end
