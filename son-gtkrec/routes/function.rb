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
require 'json' 
require 'pp'
require 'addressable/uri'

class GtkRec < Sinatra::Base

  # "/records/nsr/ns-instances"
  # "/records/vnfr/vnf-instances"
  
  get '/functions/?' do
    method = MODULE + ' GET /functions'
    logger.debug(method) {"entered with params #{params}"}

    uri = Addressable::URI.new

    # Remove list of wanted fields from the query parameter list
    field_list = params.delete('fields')
    uri.query_values = params
    logger.debug(method) {'uri.query='+uri.query}
    
    functions = VFunction.new(settings.functions_repository, logger).find(params)
    if functions
      logger.debug(method) { "functions=#{functions}"}

      if field_list
        fields = field_list.split(',')
        logger.debug(method) {"fields=#{fields}"}
        response = functions.to_json(:only => fields)
      else
        response = functions.to_json
      end
      logger.debug(method) {'leaving with response='+response}
      halt 200, response
    else
      logger.debug(method) {"leaving with \"No function with params #{uri.query} was found\""}
      json_error 404, "No function with params #{uri.query} was found"
    end
  end
  
  get '/functions/:uuid' do
    method = MODULE + ' GET /functions/:uuid'
    logger.debug(method) {"entered with :uuid=#{params[:uuid]}"}
    
    function = VFunction.new(settings.functions_catalogue, logger).find_by_uuid(params[:uuid])
    if function
      logger.debug(method) {"function: #{function}"}
      response = function.to_json
      logger.debug(method) {"leaving with response="+response}
      halt 200, response
    else
      logger.debug(method) {"leaving with \"No function with uuid #{params[:uuid]} was found\""}
      json_error 404, "No function with uuid #{params[:uuid]} was found"
    end
  end
end
