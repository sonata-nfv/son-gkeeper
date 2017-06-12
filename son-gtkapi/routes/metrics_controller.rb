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
  
  namespace '/api/v2/functions' do
    
    # TODO: how to address multiple metrics like in
    # .../metric=cpu_util,disk_usage,packets_sent&...
    
    # GET /functions/:function_uuid/instances/:instance_uuid/asynch-mon-data?metric=cpu_util&since=…&until=…
    get '/:uuid/instances/:instance_uuid/asynch-mon-data/?' do
      began_at = Time.now.utc
      log_message = 'GtkApi::GET /api/v2/functions/:uuid/instances/:instance_uuid/asynch-mon-data/?'
      logger.debug(log_message) {"entered with params #{params}"}
      # {"name":"vm_mem_perc","start": "'$tw_start'", "end": "'$tw_end'", "step": "10s", "labels": [{"labeltag":"exported_job", "labelid":"vnf"}]}
      # labels:[{"labeltag":"id", "labelid":"123456asdas255sdas"}]}'
      # TODO: validate user who's asking here
      # json_error 400, 'User must be resent' unless ...
      # json_error 400, 'User is not authorized' unless ...
      
      params.delete('splat')
      params.delete('captures')
      params.merge(parse_query_string(request.env['QUERY_STRING']))
      json_error 400, 'Metrics list is missing' unless (params.key?('metrics') && !params['metrics'].empty?)
      json_error 400, 'Starting date is missing' unless (params.key?('since') && !params['since'].empty?)
      json_error 400, 'Ending date is missing' unless (params.key?('until') && !params['until'].empty?)
    
      # Remove list of wanted fields from the query parameter list
      metrics_list = [params.delete('metrics')]
      logger.debug(log_message) {"metrics list #{metrics_list} (is a #{metrics_list.class})"}
      logger.debug(log_message) {"remaining params #{params}"}
      
      begin
        function = FunctionManagerService.find_by_uuid!(params[:uuid])
      rescue FunctionNotFoundError
        json_error 404, "Function #{params[:uuid]} not found", log_message
      end
      
      function.load_instances(params[:uuid])
      
      metrics = Metric.validate_and_create(metrics_list)
        
      # TODO: we're assuming this is treated one metric at a time
      # TODO: instance uuid should be inserted here, when it is clear how it relates
      metrics.each do |metric|
        begin
          metric.asynch_monitoring_data({
            start: params[:start],
            end: params[:send],
            step: params[:step],
            labels: params[:labels]
          })
        rescue AsynchMonitoringDataRequestNotCreatedError
          logger.debug(log_message) {'Failled request with params '+params.to_s+ ' for metric '+metric.name}
          next
        end
      end
      halt 200, 'Requested asynch metrics'
    end
    
    # …/functions/instances/:instance_uuid/synch-mon-data?metrics=cpu_util&for=<number of seconds>
    # this was
    # …/functions/:function_uuid/instances/:instance_uuid/synch-mon-data?metrics=cpu_util&for=<number of seconds>
    get '/instances/:instance_uuid/synch-mon-data/?' do
      began_at = Time.now.utc
      log_message = 'GtkApi::GET /api/v2/functions/:uuid/instances/:instance_uuid/synch-mon-data/?'
      logger.debug(log_message) {"entered with function instance #{params[:instance_uuid]}"}
      # {"metric":"vm_cpu_perc","filters":["id='123456asdas255sdas'","type='vnf'"]}
      
      content_type :json
      
      logger.debug(log_message) { 'query_string='+request.env['QUERY_STRING']}
      params.delete('splat')
      params.delete('captures')
      params.merge(parse_query_string(request.env['QUERY_STRING']))
      
      token = get_token( request.env, log_message)
      if (token.nil? || token.empty?)
        count_synch_monitoring_data_requests(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'A valid user access token was not provided', log_message
      end
      
      unless (params.key?('metrics') && !params['metrics'].empty?)
        count_synch_monitoring_data_requests(labels: {result: "bad request", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 400, 'Metrics list is missing', log_message
      end
       
      # TODO: duration is not yet being treated
      # json_error 400, 'Duration is missing' unless (params.key?(:for) && !params[:for].empty?)
      # Can we fix the ID as being function instance ID...
      # json_error 400, 'ID is missing' unless (params.key?(:id) && !params[:id].empty?)
      # ...and type as being 'vnf'?
      # json_error 400, 'Type is missing' unless (params.key?(:type) && !params[:type].empty?)
    
      #begin
      #  function = FunctionManagerService.find_by_uuid!(params[:uuid])
      #rescue FunctionNotFoundError
      #  count_synch_monitoring_data_requests(labels: {result: "not found", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
      #  json_error 404, "Function #{params[:uuid]} not found", log_message
      #end
    
      # Remove list of wanted fields from the query parameter list
      metrics_names = params.delete('metrics').split(',')
      logger.debug(log_message) { "params without metrics=#{params}"}
      
      # TODO: validate user who's asking here
      if metrics_names.empty?
        count_synch_monitoring_data_requests(labels: {result: "not found", uuid: '', elapsed_time: (Time.now.utc-began_at).to_s})
        json_error 404, "At least one metric must be given", log_message
      end

      #function.load_instances(params[:uuid])
      
      metrics = Metric.validate_and_create(metrics_names)
      ws_url = ''
      status = nil
        
      # TODO: we're assuming this is treated one metric at a time
      metrics.each do |metric|
        logger.debug(log_message) { "Metric: #{metric}"}
        begin
          resp = metric.synch_monitoring_data({filters: params[:filters]}) # TODO: add for: params[:for], 
          # {"status": "SUCCESS","metric": [<metric_name1>,<matric_name2>], "ws_url":"ws://<ws_server_ip>:8002/ws/<ws_id>"}
          # In the end, :status and :ws_url will be the ones of the last metric processed
          ws_url = resp[:ws_url]
          status = resp[:status]
        rescue SynchMonitoringDataRequestNotCreatedError
          logger.debug(log_message) {'Failled request with params '+params.to_s+ ' for metric '+metric.name}
          next
        end
      end
      count_synch_monitoring_data_requests(labels: {result: "ok", uuid: params[:instance_uuid], elapsed_time: (Time.now.utc-began_at).to_s})
      return_data = {
        status: status,
        function_uuid: params[:uuid], function_instance_uuid: params[:instance_uuid],
        metrics: metrics_names,
        ws_url: ws_url
      }
      halt 200, return_data.to_json
    end
  end
  
  private
  
  def parse_query_string(q_string)
    params = {}
    
    # Example:
    # {"metric":"vm_cpu_perc","filters":["id='123456asdas255sdas'","type='vnf'"]}
    # metrics=vm_cpu_perc,xyz&id=123456asdas255sdas&type=vnf
    list = q_string.split('&')
    list.each do |element|
      var=element.split('=')
      sub_list = var[1].split(',')
      sub_list.size == 1 ? params[var[0].to_sym] = (var[0] == 'metrics' ? [var[1]] : var[1]) : params[var[0].to_sym] = sub_list        
    end
    logger.debug(__method__.to_s) {'params='+params.to_s}
    params
  end
  
  def count_synch_monitoring_data_requests(labels:)
    name = __method__.to_s.split('_')[1..-1].join('_')
    desc = "how many synch monitoring data requests have been made"
    Metric.counter_kpi({name: name, docstring: desc, base_labels: labels.merge({method: 'GET', module: 'metrics'})})
  end
end
