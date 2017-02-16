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

class GtkVim < Sinatra::Base


  # GETs a vim_request, given an uuid
  get '/vim_requests/:uuid/?' do
    begin
      logger.debug "GtkVim: entered GET /vim_requests/#{params[:uuid]}"
      request = VimsRequest.find(params[:uuid])
      response= Hash["query_response"=>request['query_response'],"status"=>request['status']]
      if request
        if response[:status] != 'complete'
          logger.debug "GtkVim: found request for #{params[:uuid]}, but it's not complete yet"
          halt 202, json(response, {root: false})
        else
          logger.debug "GtkVim: found request for #{params[:uuid]} and it's complete"
          halt 200, json(response, {root: false})
        end
      else
        json_error 404, "GtkSrv: Request #{params[:uuid]} not found"
      end
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 404, 'GtkSrv: Request #{params[:uuid]} not found'
    end
  end

  # Gets the list o vims
  get '/vim/?' do
    logger.info "GtkVim: GET /vim with params=#{params}"
    begin
      start_request={}
      query_request = VimsRequest.create()
      query_request['status']='new'
      query_request.save

      settings.mqserver_list.publish( start_request.to_json, query_request['id'])
      response=Hash["request_uuid"=>query_request['id']]
      json_request = json(response, { root: false })
      logger.info 'GtkVim: returning GET /vim with request='+json_request
      halt 201, json_request
    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 500, 'Internal server error'
    end
  end

  # Creates a new VIM
  post '/vim/?' do
    original_body = request.body.read
    logger.info "GtkVim: entered POST /vim with original_body=#{original_body}"
    params = JSON.parse(original_body, :quirks_mode => true)
    logger.info "GtkVim: POST /vim with params=#{params}"

    begin
      start_request={}

      add_request = VimsRequest.create()
      add_request['status']='new'
      add_request.save
      start_request=params
      logger.debug "GtkVim: POST /vim #{params} with #{start_request}"
      logger.debug "GtkVim: POST /vim #{params} with #{start_request.to_yaml}"
      settings.mqserver_add.publish( start_request.to_json, add_request['id'])
      response=Hash["request_uuid"=>add_request['id']]
      json_request = json(response, { root: false })
      logger.info 'GtkVim: returning POST /vim with request='+json_request
      halt 201, json_request

    rescue Exception => e
      logger.debug(e.message)
      logger.debug(e.backtrace.inspect)
      halt 500, 'Internal server error'
    end
  end
end
