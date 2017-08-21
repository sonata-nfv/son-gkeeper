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
require 'active_support'

class RateLimiter < ManagerService

  LOG_MESSAGE = 'GtkApi::' + self.name
  
  class ThrottleNotCreatedError < StandardError; end
  class ThrottleNotSavedError < StandardError; end
  
  attr_accessor :available, :until
  
  def self.config(url:)
    method = LOG_MESSAGE + __method__.to_s
    raise ArgumentError.new('Throttle model can not be configured with nil or empty url') if (url.nil? || url.empty?)
    @@url = url
    GtkApi.logger.debug(method) {'entered with url='+url}
  end
  
  # TODO: adapt all this to the true Rate Limiter
  def self.open?(params)
    method = LOG_MESSAGE + __method__.to_s
    GtkApi.logger.debug(method) {"entered with params=#{params}"}
    throttle = self.find_by_user_uuid(params[:user_uuid])
    if throttle
      GtkApi.logger.debug(method) {"found throttle #{throttle}"}
      throttle.apply_policy(params)
    else
      up_until = GtkApi.defaults['throttle']['value'].to_i.send(GtkApi.defaults['throttle']['unit']).send('from_now')
      GtkApi.logger.debug(method) {"up_until: #{up_until}"}
      throttle = self.new(params.merge({avaiable: GtkApi.defaults['throttle']['max_value'].to_i, up_until: up_until}))
      if throttle
        GtkApi.logger.debug(method) {"created throttle #{throttle}"}
      else
        raise ThrottleNotCreatedError.new "Could not create throttle #{throttle}."
      end
    end
    if throttle.save
      true
    else
      raise ThrottleNotSavedError.new "Could not save throttle #{throttle}."
    end
    false # needed?
  end
  
  def self.find_by_user_uuid(user_uuid)
    method = LOG_MESSAGE + __method__.to_s
    GtkApi.logger.debug(method) {"entered with useruuid=#{user_uuid}"}
    
    # TODO: fetch from micro-service/db
    # self.new(params.merge({avaiable: GtkApi.defaults['throttle']['max_value'].to_i, up_until: up_until}))
  end
  
  def initialize(available:, up_until:)
    method = LOG_MESSAGE + __method__.to_s
    GtkApi.logger.debug(method) {"entered"}
    @available = available
    @until = up_until
  end

  def save
    method = LOG_MESSAGE + __method__.to_s
    GtkApi.logger.debug(method) {"entered"}
    self
  end
  
  private
  
  # TODO: turn this into a Strategy Design Pattern, with this being UserBasedPolicy (e.g.)
  def apply_policy(params)
    method = LOG_MESSAGE + __method__.to_s
    GtkApi.logger.debug(method) {"entered"}
    
    # if still on the current cycle...
    if Time.now < @until
      # ...number matters
      if @available > 0
        @available -= 1
        true
      else
        false
      end
    else # ...otherwise, reset
      @available = GtkApi.defaults['throttle']['max_value'].to_i
      @until = GtkApi.defaults['throttle']['value'].to_i.send(GtkApi.defaults['throttle']['unit']).send('from_now')
      true
    end
  end
end
