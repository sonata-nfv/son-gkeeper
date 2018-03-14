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

class Request < ActiveRecord::Base
  attr_accessor :began_at, :created_at, :updated_at, :service_uuid, :status, :request_type, :service_instance_uuid, :callback
  
  # validations a la Activerecord
  validates :service_uuid, presence: true
  
  def self.validate_request(service_instance_uuid:)
    method = GtkSrv::MODULE + "Request#validate_request"
    logger = GtkSrv.logger

    raise Exception.new(method+'A valid service instance UUID is needed') unless service_instance_uuid
    logger.debug(method) {"entered with service_instance_uuid=#{service_instance_uuid}"}
    
    logger.debug(method) {"finding request by service_instance_uuid #{service_instance_uuid}"}
    original_request = Request.find_by(service_instance_uuid: service_instance_uuid)
    unless original_request
      message = method + "service instance #{service_instance_uuid} is not registered"
      logger.debug(method) {"leaving with #{message}"}
      raise Exception.new(message) #json_error 404, message
    end 
    logger.debug(method) {"original_request is #{original_request.inspect}"}
    unless original_request['status'] == 'READY'        
      message = method + 'service instance '+service_instance_uuid + " is not running (is #{original_request['status']})"
      logger.debug(method) {"leaving with #{message}"}
      raise Exception.new(message) #json_error 404, message
    end
    logger.debug(method) {"original_request status is #{original_request['status']}"}
    original_request
  end
  
  def self.process_request(nsd:, service_instance_uuid:, type: 'UPDATE', mq_server:)
    method = GtkSrv::MODULE + "Request#{}process_request"
    logger = GtkSrv.logger
    logger.debug(method) {"entered"}
    raise Exception.new(method+'A valid NSD is needed') unless nsd
    raise Exception.new(method+'A valid service instance UUID is needed') unless service_instance_uuid
    raise Exception.new(method+'A valid mq_server is needed') unless update_server

    payload = {}
    payload['NSD'] = nsd
    payload['Instance_id'] = service_instance_uuid
    logger.debug(method) {"payload in yaml:#{payload.to_yaml}"}

    update_request = Request.create(service_uuid: nsd['uuid'], request_type: type, service_instance_uuid: service_instance_uuid)
    # Request(id: uuid, created_at: datetime, updated_at: datetime, service_uuid: uuid, status: string, request_type: string, service_instance_uuid: uuid) 
    logger.debug(method) {"update_request=#{update_request.inspect}"}
    
    unless update_request
      logger.debug(method) {'could not save update request for service instance '+service_instance_uuid}
      return nil
    end
    
    begin
      # Requests the update
      smresponse = update_server.publish( payload.to_yaml, update_request['id'])
      logger.debug(method) { "smresponse: #{smresponse.inspect}"}
      update_request2 = Request.find update_request['id']

      unless update_request2
        logger.debug(method) {"Couldn't find request with id=#{update_request['id']}"}
        return nil
      end
      
      logger.info(method) {" returning with update_request2=#{update_request2}"}
      update_request2
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      puts e.backtrace.inspect
      nil
    end
  end

  def self.build params
    log_msg = 'GtkSrv::Request#build'.freeze
    logger = GtkSrv.logger
    logger.debug(log_msg) {"with params=#{params}"}
    
    start_request={}
    start_request['instance_id'] = params['service_instance_uuid'] if (params['request_type'] == 'TERMINATE' || params['request_type'] == 'UPDATE')

    # we're not storing egresses or ingresses
    egresses = params.delete 'egresses' if params['egresses']
    ingresses = params.delete 'ingresses' if params['ingresses']
    user_data = params.delete 'user_data' if params['user_data']

    service = get_service(params)
    raise Exception.new(log_msg+': Network service not found') unless service
    logger.debug(log_msg) {"service=#{service}"}

    # we're not storing egresses or ingresses, so we're not passing them
    si_request = Request.create(service_uuid: service[:uuid], service_instance_uuid: params['service_instance_uuid'], request_type: params['request_type'], callback: params['callback'], began_at: Time.now.utc)
    raise Exception.new(log_msg+': Not possible to create '+params['request_type']+' request') unless si_request

    logger.debug(log_msg) {"with service_uuid=#{params['service_uuid']}, service_instance_uuid=#{params['service_instance_uuid']}: #{si_request.inspect}"}
    
    nsd = service[:nsd]
    nsd[:uuid] = service[:uuid]
    start_request['NSD']=nsd
  
    nsd[:network_functions].each_with_index do |function, index|
      logger.debug(log_msg) { "function=['#{function[:vnf_name]}', '#{function[:vnf_vendor]}', '#{function[:vnf_version]}']"}
      stored_function = VFunction.new(GtkSrv.functions_catalogue, logger).find_function(function[:vnf_name],function[:vnf_vendor],function[:vnf_version])
      logger.error(log_msg) {"network function not found"} unless stored_function
      logger.debug(log_msg) {"function#{index}=#{stored_function}"}
      vnfd = stored_function[:vnfd]
      vnfd[:uuid] = stored_function[:uuid]
      start_request["VNFD#{index}"]=vnfd 
      logger.debug(log_msg) {"start_request[\"VNFD#{index}\"]=#{vnfd}"}
    end
    start_request['egresses'] = egresses
    start_request['ingresses'] = ingresses
    start_request['user_data'] = user_data
    return si_request, start_request
  end
  
  private
  def self.get_service(params)
    log_message = 'GtkSrv::Request.get_service'
    logger = GtkSrv.logger
    logger.debug(log_message) {"entered with params #{params}"}
    
    # Termination requests are dealt with in a sub-class -- Update will too
    if (params['request_type'] == 'UPDATE')
      # Get the service_uuid from the creation request
      creation_request = find_creation_request_by params['service_instance_uuid']
      logger.debug(log_message) {"creation_request found = #{creation_request}"}
      unless creation_request
        logger.debug(log_message) {"No creation request found"}
        return nil
      end
      params['service_uuid'] = creation_request.to_a.first['service_uuid']
    end
    service=NService.new(GtkSrv.services_catalogue, logger).find_by_uuid(params['service_uuid'])
    return nil unless service[:status] == 200
    service[:items].first
  end
  
  protected
  def self.find_creation_request_by uuid
    Request.where("service_instance_uuid = ? AND request_type = 'CREATE' and status='READY'", uuid)
  end
end

