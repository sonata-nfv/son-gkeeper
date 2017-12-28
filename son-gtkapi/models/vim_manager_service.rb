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
require './models/manager_service.rb'

class VimManagerService < ManagerService

  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  CLASS_NAME = self.name
  LOG_MESSAGE = 'GtkApi::' + CLASS_NAME

  def self.config(url:)
    method = LOG_MESSAGE + "##{__method__}(url=#{url})"
    raise ArgumentError, CLASS_NAME+' can not be configured with nil url' if url.nil?
    raise ArgumentError, CLASS_NAME+' can not be configured with empty url' if url.empty?
    @@url = url
    GtkApi.logger.debug(method) {'entered'}
  end

  #General Case Add VIM compute and network

  def self.create_vim_rs(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {"entered"}

    saved_params = params.dup

    # Object compute-resources created from params
    #{"vim_type":String,"configuration":{"tenant_ext_router\":String, "tenant_ext_net":String, "tenant":String},
    # "city":String,"country":String, "vim_address":String,"username":String,"pass":String,"domain":String}

    cparams = {}
    cparams[:vim_type] = "Heat"
    cparams[:configuration] = {}
    cparams[:configuration][:tenant_ext_router] = params[:compute_configuration][:tenant_ext_router]
    cparams[:configuration][:tenant_ext_net] = params[:compute_configuration][:tenant_ext_net]
    cparams[:configuration][:tenant] = params[:compute_configuration][:tenant_id]
    cparams[:domain] = params[:compute_configuration][:domain]
    cparams[:country] = params[:country]
    cparams[:city] = params[:city]
    cparams[:name] = params[:name]
    cparams[:vim_address] = params[:compute_configuration][:vim_address]
    cparams[:username] = params[:compute_configuration][:username]
    cparams[:pass] = params[:compute_configuration][:pass]

    # Object networking-resources created from params
    #{"vim_type":"ovs", "vim_address":"10.100.32.200","username":"operator","city":"Athens","country":"Greece","pass":"apass",
    # "configuration":{"compute_uuid":"ecff9410-4a04-4bd7-82f3-89db93debd4a"}}

    nparams = {}
    nparams[:vim_type] = "ovs"
    nparams[:configuration] = {}
    nparams[:vim_address] = params[:networking_configuration][:vim_address]
    nparams[:username] = params[:networking_configuration][:username]
    nparams[:city] = params[:city]
    nparams[:name] = params[:name]
    nparams[:country] = params[:country]
    nparams[:pass] = params[:networking_configuration][:pass]


    begin
      GtkApi.logger.debug(method) {"@url = " + @@url}
      # Creating compute resource
      response = postCurb(url:@@url+'/vim/compute-resources', body: cparams)
      GtkApi.logger.debug(method) {"response="+response.to_s}
      #Wait a bit for the process call
      sleep 3
      request_uuid = response[:items][:request_uuid]
      GtkApi.logger.debug(method) {"request_uuid="+request_uuid.to_s}
      GtkApi.logger.debug(method) {"@url = " + @@url}
      sleep 2

      # Finding compute resource uuid
      response2 = getCurb(url:@@url+'/vim_requests/compute-resources/'+request_uuid, headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"response2="+response2.to_s}
      compute_uuid = response2[:items][:query_response][:uuid]
      GtkApi.logger.debug(method) {"compute_uuid="+compute_uuid.to_s}
      nparams[:configuration][:compute_uuid] = compute_uuid
      GtkApi.logger.debug(method) {"@url = " + @@url}

      # Creating networking resource
      response3 = postCurb(url:@@url+'/vim/networking-resources', body: nparams)
      GtkApi.logger.debug(method) {"response3="+response3.to_s}

      # Object WIM ATTACH {"wim_uuid":String, "vim_uuid":String, "vim_address":String}
      wparams={}
      wparams[:wim_uuid] = params[:wim_id]
      wparams[:vim_uuid] = compute_uuid
      wparams[:vim_address] = params[:networking_configuration][:vim_address]
      GtkApi.logger.debug(method) {"@url = " + @@url}

      # Creating link VIM -> WIM
      response4 = postCurb(url:@@url+'/wim/attach', body: wparams)
      GtkApi.logger.debug(method) {"response4="+response4.to_s}

    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  # VIM COMPUTE-RESOURCES

  def self.find_vims_comp_rs(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}
    begin
      response = getCurb(url:@@url+'/vim/compute-resources', headers:JSON_HEADERS)
      GtkApi.logger.debug(method) {'response='+response.to_s}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  def self.create_vim_comp_rs(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {"entered"}

    begin
      GtkApi.logger.debug(method) {"@url = " + @@url}
      response = postCurb(url:@@url+'/vim/compute-resources', body: params)
      GtkApi.logger.debug(method) {"response="+response.to_s}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  def self.find_vim_comp_rs_request_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}(#{uuid})"
    GtkApi.logger.debug(method) {'entered'}
    begin
      response = getCurb(url:@@url+'/vim_requests/compute-resources/'+uuid, headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"Got response: #{response}"}
      query_response = response[:items][:query_response]
      if query_response
        query_response
      else
        []
      end
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  # VIM NETWORKING-RESOURCES
  def self.find_vims_net_rs(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {'entered'}
    begin
      response = getCurb(url:@@url+'/vim/networking-resources', headers:JSON_HEADERS)
      GtkApi.logger.debug(method) {'response='+response.to_s}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  def self.create_vim_net_resources(params)
    method = LOG_MESSAGE + "##{__method__}(#{params})"
    GtkApi.logger.debug(method) {"entered"}

    begin
      GtkApi.logger.debug(method) {"@url = " + @@url}
      response = postCurb(url:@@url+'/vim/networking-resources', body: params)
      GtkApi.logger.debug(method) {"response="+response.to_s}
      response
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end

  def self.find_vim_net_rs_request_by_uuid(uuid)
    method = LOG_MESSAGE + "##{__method__}(#{uuid})"
    GtkApi.logger.debug(method) {'entered'}
    begin
      response = getCurb(url:@@url+'/vim_requests/networking-resources/'+uuid, headers: JSON_HEADERS)
      GtkApi.logger.debug(method) {"Got response: #{response}"}
      query_response = response[:items][:query_response]
      if query_response
        query_response
      else
        []
      end
    rescue => e
      GtkApi.logger.error(method) {"Error during processing: #{$!}"}
      GtkApi.logger.error(method) {"Backtrace:\n\t#{e.backtrace.join("\n\t")}"}
      nil
    end
  end
  
  def self.began_at
    log_message=LOG_MESSAGE+"##{__method__}"
    GtkApi.logger.debug(log_message) {'entered'}    
    response = getCurb(url: @@url + '/began_at')
    GtkApi.logger.debug(log_message) {"response=#{response}"}
    response
  end
end
