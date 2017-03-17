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

# require 'json' 
# require 'pp'
# require 'addressable/uri'
# require 'yaml'
# require 'bunny'
# require 'prometheus/client'
# require 'prometheus/client/push'
# require 'net/http'

require 'net/http'
require 'uri'
require 'json'

class GtkKpi < Sinatra::Base  
  
  # # default registry
  # registry = Prometheus::Client.registry 

  # def self.counter(params, pushgateway, registry)

  #   begin
  #     if (params[:base_labels] == nil) 
  #       base_labels = {}
  #     else
  #       base_labels = params[:base_labels]                
  #     end    

  #     # if counter exists, it will be increased
  #     if registry.exist?(params[:name].to_sym)
  #       counter = registry.get(params[:name])
  #       counter.increment(base_labels)
  #       Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).replace(registry)

  #     else
  #       # creates a metric type counter
  #       counter = Prometheus::Client::Counter.new(params[:name].to_sym, params[:docstring], base_labels)
  #       counter.increment(base_labels)
  #       # registers counter
  #       registry.register(counter)
        
  #       # push the registry to the gateway
  #       Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).add(registry) 
  #     end
  #   rescue Exception => e
  #     raise e
  #   end
  # end

  # def self.gauge(params, pushgateway, registry)
    
  #   begin
  #     if (params[:base_labels] == nil) 
  #       base_labels = {}
  #     else
  #       base_labels = params[:base_labels]                
  #     end

  #     # if gauge exists, it will be updated
  #     if registry.exist?(params[:name].to_sym)
  #       gauge = registry.get(params[:name])

  #       logger.debug "Getting gauge value"
  #       value = gauge.get(base_labels)
        
  #       if params[:operation]=='inc'
  #         value = value.to_i + 1
  #       else
  #         value = value.to_i - 1
  #       end

  #       logger.debug "Setting gauge value"
  #       gauge.set(base_labels,value)

  #       Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).replace(registry)

  #     else
  #       # creates a metric type gauge
  #       gauge = Prometheus::Client::Gauge.new(params[:name].to_sym, params[:docstring], base_labels)
  #       gauge.set(base_labels, 1)
  #       # registers gauge
  #       registry.register(gauge)
        
  #       # push the registry to the gateway
  #       Prometheus::Client::Push.new(params[:job], params[:instance], pushgateway).add(registry) 
  #     end
  #   rescue Exception => e
  #     raise e
  #   end
  # end
  
  # put '/kpis/?' do
  #   original_body = request.body.read
  #   logger.info "GtkKpi: entered PUT /kpis with original_body=#{original_body}"
  #   params = JSON.parse(original_body, :symbolize_names => true)
  #   logger.info "GtkKpi: PUT /kpis with params=#{params}"    
  #   pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s

  #   begin

  #     if params[:metric_type]=='counter' 
  #       GtkKpi.counter(params, pushgateway, registry)
  #     else
  #       GtkKpi.gauge(params, pushgateway, registry)
  #     end

  #     logger.info 'GtkKpi: '+params[:metric_type]+' '+params[:name].to_s+' updated/created'
  #     halt 201
      
  #   rescue Exception => e
  #     logger.debug(e.message)
  #     logger.debug(e.backtrace.inspect)
  #     halt 400
  #   end           
  # end

  # get '/kpis/?' do
  #   pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s
  #   prometheus_API_url = 'http://'+settings.pushgateway_host+':'+settings.prometheus_port.to_s+'/api/v1/series?match[]={exported_job="'+settings.prometheus_job_name+'"}' 
  #   begin
  #     if params.empty?
  #       #get all sonata metrics
  #       url = URI.parse(prometheus_API_url)
  #       req = Net::HTTP::Get.new(url.to_s)
  #       res = Net::HTTP.start(url.host, url.port) {|http|
  #         http.request(req)
  #       }
  #       halt 200, res.body
  #       logger.info 'GtkKpi: sonata metrics list retrieved'
  #     else        
  #       logger.info "GtkKpi: entered GET /kpis with params=#{params}"        

  #         if registry.exist?(params[:name].to_sym)
  #           metric = registry.get(params[:name])
            
  #           if ("#{params[:base_labels]}" == '') 
  #             base_labels = {}
  #           else
  #             base_labels = JSON.parse(eval("#{params[:base_labels]}").to_json, :symbolize_names => true)              
  #           end

  #           value = metric.get(base_labels)
  #         end

  #       logger.info 'GtkKpi: '+params[:name].to_s+' metric value retrieved: '+value.to_s
  #       response = {'value' => value}
  #       halt 200, response.to_json
  #     end
  #   rescue Exception => e
  #     logger.debug(e.message)
  #     logger.debug(e.backtrace.inspect)
  #     halt 400
  #   end
  # end

    post '/kpis/?' do
    original_body = request.body.read
    logger.info "GtkKpi: entered PUT /kpis with original_body=#{original_body}"
    params = JSON.parse(original_body, :symbolize_names => true)
    logger.info "GtkKpi: PUT /kpis with params=#{params}"    
    pushgateway = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s
    prometheus = 'http://'+settings.pushgateway_host+':'+settings.prometheus_port.to_s

    begin

      post_url = pushgateway + '/metrics/job/'+params[:job]+'/instance/'+params[:instance]

      query_labels = params[:base_labels].to_s
      query_labels = query_labels.gsub(":", "")
      query_labels = query_labels.gsub("=>","=")
      get_url = prometheus + '/api/v1/query?query='+params[:name]+query_labels

      if params[:operation]=='set'
        if ("#{params[:value]}" != '')            
          new_value = params[:value]
          logger.debug "GtkKpi: new_value = "+new_value.to_s
        end
      else
        logger.debug "GtkKpi: inc/dec operation"
        if ("#{params[:value]}" == '') 
          factor = 1
        else
          factor = params[:value].to_f
        end

        # getting old value
        response = GtkKpi.getKpiValue(params)

        if response["value"].to_s != "[]"
          old_value = response["value"].to_f
        else
          old_value = 0
        end

        # getting new value
        
        logger.debug "GtkKpi: obtaining new value"
        if params[:metric_type]=='counter'
          # if no set -> it can only be incremented
          logger.debug "GtkKpi: new value = "+old_value.to_s+" + "+factor.to_s
          new_value = old_value + factor
        else
          if params[:operation]=='inc'
            new_value = old_value + factor
            logger.debug "GtkKpi: new value = "+old_value.to_s+" - "+factor.to_s
          else 
            #dec
            new_value = old_value - factor
          end
        end        
      end

      # creating data binary
      data = "#TYPE "+params[:name].to_s+" "+params[:metric_type].to_s+"\n"+params[:name].to_s+query_labels+" "+new_value.to_s+"\n"
      logger.debug "GtkKpi: setting new value - data="+data+", url="+post_url      

      url = URI.parse(post_url)
      http = Net::HTTP.new(url.host, url.port)
      response = http.post(url.path, data, {'Content-type'=>'text/plain;charset=utf-8'})
      halt 201
      
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 400
    end           
  end

  get '/kpis/?' do
    begin
      params = JSON.parse("#{params}".to_json, :symbolize_names => true)
      response = GtkKpi.getKpiValue(params)
      logger.info 'GtkKpi: sonata metric obtained'
      halt 200, response

    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 400
    end
  end

  def self.getKpiValue(params)    
    begin
      pushgateway_url = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s
      prometheus_url = 'http://'+settings.prometheus_host+':'+settings.prometheus_port.to_s
      prometheus_query = prometheus_url+'/api/v1/query?query='+"#{params[:name]}"
      pushgateway_query = pushgateway_url+"/metrics"

      query_labels = params[:base_labels].to_s
      query_labels = query_labels.gsub(":", "")
      query_labels = query_labels.gsub("=>","=")

      # checking if metric value exists in pushgateway

      #url = URI.parse(pushgateway_query)
      #req = Net::HTTP::Get.new(url.to_s)
      #res = Net::HTTP.start(url.host, url.port) {|http|
      #  http.request(req)
      #}      
      
      #regExp = "^"+"#{params[:name]}"+"{(.*)"+query_labels[1..-1].delete(' ')
      #regExp = Regexp.new regExp

      kpi=""

      #res.body.each_line do |li|
      #  kpi = li if (li =~ regExp)
      #end

      kpi = system "prom2json "+pushgateway_query+" | jq '.[]|select(.name=="+params[:name]+")'"
      logger.debug "json obtained from pushgateway: "+kpi.to_s

      response = {kpi:params[:name],base_labels:query_labels,value:[]} 

      if kpi != ""
        logger.debug "kpi present in pushgateway: "+kpi.split.last
        response["value"] = kpi.split.last
      else

        # if metric does not exist in pushgateway, check prometheus    
        if "#{params[:base_labels]}" != ''
          prometheus_query = prometheus_query + query_labels
        end

        logger.debug "getting value with query = "+prometheus_query

        url = URI.parse(prometheus_query)
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }

        resp = JSON.parse(res.body)

        if resp["data"]["result"].to_s != "[]"
          logger.debug "kpi present in prometheus!"
          response["value"] = resp["data"]["result"][0]["value"][1]                  
        end                
      end
      
      response

    rescue Exception => e
      raise e
    end
  end
end