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
require 'sinatra/namespace'
class GtkApi < Sinatra::Base

  register Sinatra::Namespace
  
  namespace '/api/v2/kpis' do
    options '/?' do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST'      
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
      halt 200
    end
  
    # GET many kpis
    get '/?' do
      log_message = 'GtkApi::GET /api/v2/kpis/?'
      logger.debug(log_message) {"entered with params=#{params}"}
    
      json_error(400, 'The KPI name must be given', log_message) if (params[:name].nil? || params[:name].empty?)
      json_error(400, 'The KPI start date must be given', log_message) if (params[:start].nil? || params[:start].empty?)
      json_error(400, 'The KPI end date must be given', log_message) if (params[:end].nil? || params[:end].empty?)
      json_error(400, 'The KPI step must be given', log_message) if (params[:step].nil? || params[:step].empty?)
    
      # POST .../api/v1/prometheus/metrics/data with body {"name":"user_registrations","start": "2017-05-03T11:41:22Z", "end": "2017-05-03T11:51:11Z", "step": "10s", "labels":[]}
      #url = 'http://'+settings.pushgateway_host+':'+settings.pushgateway_port.to_s
      body = {"name": params[:name],"start": params[:start], "end": params[:end], "step": params[:step], "labels":[]}
      # 200 with metrics
      # 400 Bad request when json data have syntax error
      # 415 on missinh header
      begin
        resp = Metric.get_kpis(body)
        GtkApi.logger.debug(log_message) {"received response was #{resp}"}
        
        #json_error(400, 'No KPIs collection received', log_message) if resp[:items]

        GtkApi.logger.debug(log_message) {"#{resp.count} metrics were received"} 
        resp.to_json
      rescue MetricNotCollectedError => e
        logger.debug(e.message)
        logger.debug(e.backtrace.inspect)
        json_error(400, 'Error collecting the KPIs', log_message)
      end
    end  

    # PUT a request
    put '/?' do
      MESSAGE = "GtkApi::PUT /api/v2/kpis"
      params = JSON.parse(request.body.read)
      unless params.nil?
        logger.debug(MESSAGE) {"entered with params=#{params}"}
        resp = KpiManagerService.update_metric(params)
        logger.debug(MESSAGE) {"resp=#{resp.inspect}"}
        case resp[:status]
        when 201            
          halt 201
        else
          message = "Metric does not updated for update_metric #{params}"
          logger.error(MESSAGE) {message}
          json_error resp[:status], message
        end                
      end
      logger.debug(MESSAGE) { "leaving with 'No request id specified'"}
      json_error 400, 'No params specified for the create request'
    end
  end
  
  private 
  def query_string
    request.env['QUERY_STRING'].empty? ? '' : '?' + request.env['QUERY_STRING'].to_s
  end

  def request_url
    request.env['rack.url_scheme']+'://'+request.env['HTTP_HOST']+request.env['REQUEST_PATH']
  end
end
