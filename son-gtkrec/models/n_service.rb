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

class NService
  
  JSON_HEADERS = { 'Accept'=> 'application/json', 'Content-Type'=>'application/json'}
  
  def initialize(catalogue, logger)
    @catalogue = catalogue
    @logger = logger
  end
  
  def find(params)
    @logger.debug "NService.find(#{params})"
    services = @catalogue.find(params)
    @logger.debug "NService.find: #{services}"
    services
  end

  def find_by_uuid(uuid)
    @logger.debug "NService.find_by_uuid(#{uuid})"
    service = @catalogue.find_by_uuid(uuid)
    @logger.debug "NService.find_by_uuid: #{service}"
    service
  end
end
