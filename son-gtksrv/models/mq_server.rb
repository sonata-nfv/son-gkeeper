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
require 'bunny'
require 'pp'
require 'yaml'
require 'json' 

class MQServer
  attr_accessor :url, :correlation_ids
  
  SERVER_QUEUE = 'service.instances.create'
  
  def initialize(url,logger)
    @url = url
    @logger=logger
    @channel = Bunny.new(url,:automatically_recover => false).start.create_channel
    @topic = @channel.topic("son-kernel", :auto_delete => false)
    @queue   = @channel.queue(SERVER_QUEUE, :auto_delete => true).bind(@topic, :routing_key => SERVER_QUEUE)
    self.consume
  end

  def publish(msg, correlation_id)
    @logger.debug "MQServer.publish("+msg+", "+correlation_id+")"
    @topic.publish(msg, :content_type =>'text/yaml', :routing_key => SERVER_QUEUE, :correlation_id => correlation_id, :reply_to => @queue.name)
  end
  
  def consume
    @queue.subscribe do |delivery_info, properties, payload|
      begin
        @logger.debug "MQServer.consume: delivery_info: #{delivery_info}"
        @logger.debug "MQServer.consume: properties: #{properties}"
        @logger.debug "MQServer.consume: payload: #{payload}"
        
        # This is because the payload is being returned as a string like
        # {error: null, status: INSTANTIATING, timestamp: 1465488253.8547997}
        parsed_payload = YAML.load(payload)
        #status = payload.split(',')[1].split(':')[1].strip
        status = payload['status']
        @logger.debug "MQServer.consume: status: #{status}"
        unless status == ''
          request = Request.find_by(id: properties[:correlation_id])
          if request
            @logger.debug "MQServer.consume: request[status] "+request['status']+" turned into "+status
            request['status']=status  
            begin
              request.save
              @logger.debug "MQServer.consume: request saved"
            rescue Exception => e
              @logger.error e.message
        	    @logger.error e.backtrace.inspect
            end
          else
            @logger.error "MQServer.consume: request "+properties[:correlation_id]+" not found"
          end
        else
          @logger.debug "MQServer.consume: status not present"
        end
      rescue Exception => e
        @logger.error e.message
  	    @logger.error e.backtrace.inspect
      end
    end
  end
end