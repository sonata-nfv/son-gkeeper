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
require 'net/http'

class GtkKpi < Sinatra::Base  
  
  # default registry
  registry = Prometheus::Client.registry 

  def self.counter(params, pushgateway, registry)

    # if counter exists, it will be increased
    if registry.exist?(params[:name].to_sym)
      counter = registry.get(params[:name])
      counter.increment(params[:base_labels])
      Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).replace(registry)

    else
      # creates a metric type counter
      counter = Prometheus::Client::Counter.new(params[:name].to_sym, params[:docstring], params[:base_labels])
      counter.increment(params[:base_labels])
      # registers counter
      registry.register(counter)
        
      # push the registry to the gateway
      Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).add(registry) 
    end      
  end

  def self.gauge(params, pushgateway, registry)
    
    # if gauge exists, it will be updated
    if registry.exist?(params[:name].to_sym)
      gauge = registry.get(params[:name])
      value = gauge.get(params[:base_labels])
        
      if params[:operation]=='inc'
        value = value.to_i + 1
      else
        value = value.to_i - 1
      end

      gauge.set(params[:base_labels],value)

      Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).replace(registry)

    else
      # creates a metric type gauge
      gauge = Prometheus::Client::Gauge.new(params[:name].to_sym, params[:docstring], params[:base_labels])
      gauge.set(params[:base_labels], 1)
      # registers gauge
      registry.register(gauge)
        
      # push the registry to the gateway
      Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).add(registry) 
    end     
  end
  
  put '/kpis/?' do
    original_body = request.body.read
    logger.info "GtkKpi: entered PUT /kpis with original_body=#{original_body}"
    params = JSON.parse(original_body, :symbolize_names => true)
    logger.info "GtkKpi: PUT /kpis with params=#{params}"    
    pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s

    begin

      if params[:metric_type]=='counter' 
        GtkKpi.counter(params, pushgateway, registry)
      else
        GtkKpi.gauge(params, pushgateway, registry)
      end

      logger.info 'GtkKpi: '+params[:metric_type]+' '+params[:name].to_s+' updated/created'
      halt 201
      
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 500, 'Internal server error'
    end           
  end

  get '/kpis/?' do
    pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s
    prometheus_API_url = 'http://'+settings.pushgateway_host+':'+settings.prometheus_port.to_s+'/api/v1/series?match[]={exported_job="'+settings.prometheus_job_name+'"}' 
    begin
      if params.empty?
        #get all sonata metrics
        url = URI.parse(prometheus_API_url)
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        halt 200, res.body
        logger.info 'GtkKpi: sonata metrics list retrieved'
      else
        base_labels = JSON.parse(eval("#{params[:base_labels]}").to_json, :symbolize_names => true)
        logger.info "GtkKpi: entered GET /kpis with metric name=#{params[:name]} and labels=#{base_labels}"        

          if registry.exist?(params[:name].to_sym)
            metric = registry.get(params[:name])
            value = metric.get(base_labels)
          end

        logger.info 'GtkKpi: '+params[:name].to_s+' metric value retrieved: '+value.to_s
        response = {'value' => value}
        halt 200, response.to_json
      end
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 500, 'Internal server error'
    end
  end
end