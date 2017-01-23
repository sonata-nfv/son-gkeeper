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
require 'json' 
require 'pp'
require 'addressable/uri'
require 'yaml'
require 'bunny'
require 'prometheus/client'
require 'prometheus/client/push'

class GtkKpi < Sinatra::Base  
  

  # Creates a new metric (counter)
  post '/kpi/?' do
    original_body = request.body.read
    logger.info "GtkVim: entered POST /kpi with original_body=#{original_body}"
    params = JSON.parse(original_body, :symbolize_names => true)
    logger.info "GtkKpi: POST /kpi with params=#{params}"    
    pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s

    begin

      # default registry
      registry = Prometheus::Client.registry  

      # if counter exists, it will be increased
      if registry.exist?(params[:name].to_sym)
        counter = registry.get(params[:name])
        counter.increment
        Prometheus::Client::Push.new(params[:job], params[:instance], params[:prometheusServer]).replace(registry)

      else
        # creates a metric type counter
        counter = Prometheus::Client::Counter.new(params[:name].to_sym, params[:docstring], params[:base_labels])
        counter.increment
        # registers counter
        registry.register(counter)
        
        # push the registry to the gateway
        Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).add(registry) 
      end
      
      logger.info 'GtkKpi: counter '+params[:name].to_s+' updated/created'
      halt 201
      
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 500, 'Internal server error'
    end
  end
end
