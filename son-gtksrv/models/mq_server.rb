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
require 'addressable/uri'
require 'yaml'
require 'json' 

class MQServer
  
  
  attr_reader
  attr_accessor :correlation_ids
  
  def initialize(url,logger)
    
    @logger=logger    
    conn = Bunny.new(url,:automatically_recover => false)
    conn.start
    self.correlation_ids=Hash.new
    
    ch   = conn.create_channel
    @ch             = ch
    @x              = ch.topic("son-kernel", :auto_delete => false)
    @server_queue   = "service.instances.create"
    
    that = self
    @q = ch.queue(@server_queue, :auto_delete => true).bind(@x, :routing_key => @server_queue)
    
    @q.subscribe do |delivery_info, properties, payload|
    
    
     begin	
      if properties[:headers]!=nil &&
         properties[:headers]['type']=='reply' && 
	 self.correlation_ids[properties[:correlation_id]] != nil 
        
	parsed_payload = YAML.load(payload)
	
	
	
	request = Request.find_by(id: properties[:correlation_id])

	if request['status']!=nil &&
          (request['status']=='ERROR' || request['status']=='REJECTED' || request['status']=='Deployment completed')
	
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
        ObjectSpace.define_finalizer( self, proc { conn.close } )
  end

  
  def call_sm(n,correlation_id)
   
    self.correlation_ids[correlation_id]=correlation_id
    @logger.debug(correlation_id)
    @x.publish(n.to_s,
      :routing_key    => @server_queue,
      :correlation_id => correlation_id,
      :reply_to       => @q.name)

  end
  
  
end

