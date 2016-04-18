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
require 'sinatra/activerecord'

class Request < ActiveRecord::Base
    
  # Establish a connection with a Model (a Table) belong to a database different from default 
  # establish_connection(ENV['SAR_DB_URL'] || 'postgres://YOURUSERNAME:YOURPASSWORD@HOSTIPADDRESS/sar')

  # set table Name, in case in the existing datbase there is not a 'Rails naming' convention
  # self.table_name = "notes"

  # validations a la Activerecord   
  validates :service_uuid, presence: true
end

