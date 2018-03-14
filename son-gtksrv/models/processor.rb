## SONATA - Gatekeeper
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
require 'sinatra/activerecord'
require 'json'
require 'yaml'

class Processor

  def initialize(logger, s_catalogue, f_catalogue)
    @logger, @s_catalogue, @f_catalogue = logger, s_catalogue, f_catalogue
    @mq_server = nil
  end
  
  def call(params)
    case params[:request_type]
    when 'CREATE'
      @mq_server = GtkSrv.create_mqserver
      create(params)
    when 'TERMINATE'
      @mq_server = GtkSrv.terminate_mqserver
      terminate(params[:service_instance_uuid])
    when 'UPDATE'
      @mq_server = GtkSrv.update_mqserver
      update(params)
    end    
  end
  
  private
  def create(params)
    log_msg = 'Processor.create'
    
    # we're not storing egresses or ingresses
    egresses = params.delete 'egresses' if params['egresses']
    ingresses = params.delete 'ingresses' if params['ingresses']
    user_data = params.delete 'user_data' if params['user_data']
    start_request={}

    # we're not storing egresses or ingresses, so we're not passing them
    si_request = Request.create(service_uuid: params[:service_uuid], request_type: params[:request_type], callback: params[:callback], began_at: Time.now.utc)
    return nil if si_request.empty?
    
    service = NService.new(@s_catalogue, @logger).find_by_uuid(params[:service_uuid])

    nsd = service[:nsd]
    nsd[:uuid] = service[:uuid]
    start_request['NSD']=nsd
  
    functions = build_function_list(nsd[:network_functions])
    start_request.merge! functions
  
    start_request['egresses'] = egresses
    start_request['ingresses'] = ingresses
    start_request['user_data'] = user_data
    
    start_request_yml = YAML.dump(start_request.deep_stringify_keys)

    smresponse = @mq_server.publish( start_request_yml.to_s, si_request['id'] || si_request[:id])
    si_request
  end
  
  def terminate(si_uuid)
    log_msg = 'Processor.terminate'
    
    start_request={}

    # for TERMINATE, service_uuid has to be found first
    service = get_service(si_uuid)
    return nil if service.empty?

    si_request = Request.create(service_uuid: service[:uuid], service_instance_uuid: si_uuid, request_type: 'TERMINATE', callback: '', began_at: Time.now.utc)
    return nil if si_request.empty?
    
    nsd = service[:nsd]
    nsd[:uuid] = service[:uuid]
    start_request['NSD']=nsd

    functions = build_function_list(nsd[:network_functions])
    start_request.merge! functions
    start_request['instance_id'] = si_uuid
    start_request_yml = YAML.dump(start_request.deep_stringify_keys)

    smresponse = @mq_server.publish( start_request_yml.to_s, si_request['id'] || si_request[:id])
    si_request
  end
  
  def update(params)
  end
  
  class Hash
    def deep_stringify_keys
      deep_transform_keys{ |key| key.to_s }
    end
    def deep_transform_keys(&block)
      _deep_transform_keys_in_object(self, &block)
    end
    def _deep_transform_keys_in_object(object, &block)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[yield(key)] = _deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map {|e| _deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end
  end
  
  private
  def find_creation_request(si_uuid)
    # Get the service_uuid from the creation request
    Request.where("service_instance_uuid = ? AND request_type = 'CREATE'", si_uuid)
  end
  def get_service(si_uuid)
    # Get the service_uuid from the creation request
    creation_request = find_creation_request(si_uuid)
    NService.new(@s_catalogue, @logger).find_by_uuid(creation_request.to_a[0][:service_uuid])
  end
  
  def build_function_list(functions)
    log_msg = 'Processor#build_function_list'
    result = {}
    functions.each_with_index do |function, index|
      stored_function = VFunction.new(@f_catalogue, @logger).find_function( function[:vnf_name], function[:vnf_vendor], function[:vnf_version])
      if stored_function.empty?
        $stderr.puts "#{log_msg}: network function not found"
        next
      end
      vnfd = stored_function[:vnfd]
      vnfd[:uuid] = stored_function[:uuid]
      result["VNFD#{index}"]=vnfd 
    end
    result
  end
end
