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

class GtkFnct < Sinatra::Base

  get '/functions/?' do
    logger.debug "GtkFnct: entered GET /functions with params #{params}"
    uri = Addressable::URI.new

    # Remove list of wanted fields from the query parameter list
    field_list = params.delete('fields')
    uri.query_values = params
    logger.debug 'GtkFnct: GET /functions: uri.query='+uri.query
    logger.debug "GtkFnct: GET /functions: params=#{params}"
    
    functions = VFunction.new(settings.services_catalogue, logger).find(params)
    if functions
      logger.debug "GtkFnct: GET /functions: #{functions}"

      if field_list
        fields = field_list.split(',')
        logger.debug "GtkFnct: GET /functions: fields=#{fields}"
        response = functions.to_json(:only => fields)
      else
        response = functions.to_json
      end
      logger.debug "GtkFnct: leaving GET /functions?#{uri.query} with response="+response
      halt 200, response
    else
      logger.debug "GtkFnct: leaving GET /functions?#{uri.query} with \"No function with params #{uri.query} was found\""
      json_error 404, "No function with params #{uri.query} was found"
    end
  end
  
  get '/functions/:uuid' do
    unless params[:uuid].nil?
    logger.info "GtkFnct: entered GET \"/functions/#{params[:uuid]}\""
    function = VFunction.new(settings.services_catalogue, logger).find_by_uuid(params[:uuid])
      if function && function.is_a?(Hash) && function['uuid']
        logger.info "GtkFnct: in GET /functions/#{params[:uuid]}, found function #{function}"
        response = function.to_json
        logger.info "GtkFnct: leaving GET /functions/#{params[:uuid]} with response="+response
        halt 200, response
      else
        logger.error "GtkFnct: leaving GET \"/functions/#{params[:uuid]}\" with \"No function with UUID=#{params[:uuid]} was found\""
        json_error 404, "No function with UUID=#{params[:uuid]} was found"
      end
    end
    logger.error "GtkFnct: leaving GET \"/functions/#{params[:uuid]}\" with \"No function UUID specified\""
    json_error 400, 'No function UUID specified'
  end
  
  
  get '/admin/logs' do
    logger.debug "GtkFnct: entered GET /admin/logs"
    File.open('log/'+ENV['RACK_ENV']+'.log', 'r').read
  end  
end
