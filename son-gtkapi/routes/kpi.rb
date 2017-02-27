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
    before do
       if request.request_method == 'OPTIONS'
         response.headers['Access-Control-Allow-Origin'] = '*'
         response.headers['Access-Control-Allow-Methods'] = 'POST'      
         response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With'
         halt 200
       end
     end
  
    # GET many kpis
    get '/?' do
      MESSAGE = "GtkApi::GET /api/v2/kpis"+query_string
      
      logger.info(MESSAGE) {"entered"}
      kpis = KpiManagerService.get_metric(params)
      logger.debug(MESSAGE) { "kpis= #{kpis}"}
      if kpis        
        [200, kpis.to_json]
      else
        logger.info(MESSAGE) { "leaving GET with 'No get kpis request were created'"}
        json_error 400, 'No get list of kpis request was created'
      end      
    end

    # PUT a request
    put '/?' do
      MESSAGE = "GtkApi::PUT /api/v2/kpis"
      params = JSON.parse(request.body.read)
      unless params.nil?
        logger.debug(MESSAGE) {"entered with params=#{params}"}
        new_request = KpiManagerService.update_metric(params)
        if new_request
          logger.debug(MESSAGE) {"new_request =#{new_request}"}
          halt 201, new_request.to_json
        else
          logger.debug(MESSAGE) { "leaving with 'No kpi update request was created'"}
          json_error 400, 'No kpi update_request was created'
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
