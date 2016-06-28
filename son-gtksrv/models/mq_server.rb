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
    logmsg= 'MQServer.publish'
    @logger.debug(logmsg) {"msg="+msg+", correlation_id="+correlation_id}
    @topic.publish(msg, :content_type =>'text/yaml', :routing_key => SERVER_QUEUE, :correlation_id => correlation_id, 
      :reply_to => @queue.name, :app_id => 'son-gkeeper')
  end
  
  def consume
    logmsg= 'MQServer.consume'
    @queue.subscribe do |delivery_info, properties, payload|
      begin
        @logger.debug(logmsg) { "delivery_info: #{delivery_info}"}
        @logger.debug(logmsg) { "properties: #{properties}"}
        @logger.debug(logmsg) { "payload: #{payload}"}

        # We know our own messages, so just skip them
        unless properties[:app_id] == 'son-gkeeper'
          # We're interested in app_id == 'son-plugin.slm'
          parsed_payload = YAML.load(payload)
          @logger.debug(logmsg) { "parsed_payload: #{parsed_payload}"}
          status = parsed_payload['status']
          if status
            @logger.debug(logmsg) { "status: #{status}"}
            request = Request.find_by(id: properties[:correlation_id])
            if request
              @logger.debug(logmsg) { "request[status] #{request['status']} turned into "+status}
              request['status']=status  
              begin
                request.save
                @logger.debug(logmsg) { "request saved"}
              rescue Exception => e
                @logger.error e.message
          	    @logger.error e.backtrace.inspect
              end
            else
              @logger.error(logmsg) { "request "+properties[:correlation_id]+" not found"}
            end
          else
            @logger.debug('MQServer.consume') {'status not present'}
          end
        end
      rescue Exception => e
        @logger.error e.message
  	    @logger.error e.backtrace.inspect
      end
    end
  end
end