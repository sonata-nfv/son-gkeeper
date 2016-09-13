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
require 'yaml'

class Request < ActiveRecord::Base
    
  # validations a la Activerecord
  validates :service_uuid, presence: true
  
  def self.validate_request(service_instance_uuid:, logger:)
    method = GtkSrv::MODULE + ": Request#validate_request: "

    raise Exception.new(method+'A valid service instance UUID is needed') unless service_instance_uuid
    raise Exception.new(method+'A valid logger is needed') unless logger
    logger.debug(method) {"entered with service_instance_uuid=#{service_instance_uuid}, logger=#{logger}"}
    
    logger.debug(method) {"finding request by service_instance_uuid #{service_instance_uuid}"}
    original_request = Request.find_by(service_instance_uuid: service_instance_uuid)
      logger.debug(method) {"original_request is #{original_request.inspect}"}
    if original_request
      if original_request['status'] == 'READY'        
        logger.debug(method) {"original_request status is #{original_request['status']}"}
        original_request
      else
        message = method + 'service instance '+service_instance_uuid + " is not running (is #{original_request['status']})"
        logger.debug(method) {"leaving with #{message}"}
        raise Exception.new(message) #json_error 404, message
      end
    else
      message = method + "service instance #{service_instance_uuid} is not registered"
      logger.debug(method) {"leaving with #{message}"}
      raise Exception.new(message) #json_error 404, message
    end 
  end
  
  def self.process_request(nsd:, service_instance_uuid:, update_server:, logger:)
    method = GtkSrv::MODULE + "Request.process_request"
    logger.debug(method) {"entered"}
    raise Exception.new(method+'A valid NSD is needed') unless nsd
    raise Exception.new(method+'A valid service instance UUID is needed') unless service_instance_uuid
    raise Exception.new(method+'A valid update_server is needed') unless update_server
    raise Exception.new(method+'A valid logger is needed') unless logger

    payload = {}
    payload['NSD'] = nsd
    payload['Instance_id'] = service_instance_uuid
    #nsd_yml = YAML.dump(nsd)
    logger.debug(method) {"payload in yaml:#{payload.to_yaml}"}

    update_request = Request.create(service_uuid: nsd['uuid'], request_type: 'UPDATE', service_instance_uuid: service_instance_uuid)
    # Request(id: uuid, created_at: datetime, updated_at: datetime, service_uuid: uuid, status: string, request_type: string, service_instance_uuid: uuid) 
    logger.debug(method) {"update_request=#{update_request.inspect}"}
    
    if update_request
      begin
        # Requests the update
        smresponse = update_server.publish( payload.to_yaml, update_request['id'])
        logger.debug(method) { "smresponse: #{smresponse.inspect}"}
        #update_response = YAML.load(smresponse)
        #logger.debug(method) { "update_response: #{update_response}"}
    
        #status = update_response['status']
        #if status
        #  logger.debug(method) { "update_request[status] #{update_request['status']} turned into "+status}
        #  update_request['status']=status  
        #  begin
        #    update_request.save
        #    logger.debug(method) { "request saved"}
        update_request2 = Request.find update_request['id']
        if update_request2
          json_request = json(update_request2, { root: false })
          logger.info(method) {' returning with request='+json_request}
          halt 201, json_request
        else
          message = method + "Couldn't find request with id=#{update_request['id']}"
          logger.debug(method) {"leaving with #{message}"}
          json_error 404, message
        end
            #rescue Exception => e
          #   logger.error e.message
        	#   logger.error e.backtrace.inspect
          #end
          #else
          #message = method + 'status not present'
          #logger.debug(method) {"leaving with #{message}"}
          #json_error 404, message
          #end
      rescue Exception => e
        logger.debug(e.message)
        logger.debug(e.backtrace.inspect)
        puts e.backtrace.inspect
        #halt 500, 'Internal server error'
        {}
      end
    else
      message = method + 'could not save update request for service instance '+service_instance_uuid
      logger.debug(method) {"leaving with #{message}"}
      json_error 404, message
    end
  end

end

# Establish a connection with a Model (a Table) belong to a database different from default 
# establish_connection(ENV['SAR_DB_URL'] || 'postgres://YOURUSERNAME:YOURPASSWORD@HOSTIPADDRESS/sar')

# set table Name, in case in the existing datbase there is not a 'Rails naming' convention
# self.table_name = "notes"
