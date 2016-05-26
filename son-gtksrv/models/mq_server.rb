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
  attr_accessor :correlation_ids
  
  SERVER_QUEUE = 'service.instances.create'
  
  def initialize(url,logger)
    @logger=logger
    @channel = Bunny.new(url,:automatically_recover => false).start.create_channel
    @topic = @channel.topic("son-kernel", :auto_delete => false)
    @queue   = @channel.queue(SERVER_QUEUE, :auto_delete => true).bind(@topic, :routing_key => SERVER_QUEUE)

    self.correlation_ids=Hash.new
    
  end
  
  def call_sm(n,correlation_id)
    self.correlation_ids[correlation_id]=correlation_id
    @logger.debug(correlation_id)
    @topic.publish(n.to_s, :routing_key => SERVER_QUEUE, :correlation_id => correlation_id,:reply_to => @q.name)
  end

  def emit(msg, correlation_id)
    @topic.publish(msg, :routing_key => SERVER_QUEUE, :correlation_id => correlation_id)
  end
  
  def consume
    @queue.subscribe do |delivery_info, properties, payload|
      begin
        pp "delivery_info: #{delivery_info}"
        pp "properties: #{properties}"
        pp "payload: #{payload}"
        if valid_response( properties, self.correlation_ids)
          parsed_payload = YAML.load(payload)
          request = Request.find_by(id: properties[:correlation_id])

  	      if valid(request)
            self.correlation_ids.delete(properties[:correlation_id])
          end
          request['status']=parsed_payload['status']
          request.save
        end
      rescue Exception => e
        @logger.debug(e.message)
  	    @logger.debug(e.backtrace.inspect)
      end
    end
  end
  
  private 
  
  def valid_response(properties, correlation_ids)
    properties[:headers]!=nil && properties[:headers]['type']=='reply' && correlation_ids[properties[:correlation_id]] != nil 
  end
  
  def valid(request)
    request['status']!=nil && (request['status']=='ERROR' || request['status']=='REJECTED' || request['status']=='Deployment completed')
  end
end

