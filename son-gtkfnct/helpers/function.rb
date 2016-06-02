# SONATA - Gatekeeper
#
# Copyright 2015-2017 Portugal Telecom Inovacao/Altice Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# encoding: utf-8
module GtkFnctHelper
  def correct(val, default_val)
    return defalt_val unless val
    return 0 if val < 0
    val
  end

  def json_error(code, message)
    msg = {'error' => message}
    logger.error msg.to_s
    halt code, {'Content-type'=>'application/json'}, msg.to_json
  end

  def valid?(uuid)
    uuid.match /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
    uuid == $&
  end
  
  def keyed_hash(hash)
    Hash[hash.map{|(k,v)| [k.to_sym,v]}]
  end
end
