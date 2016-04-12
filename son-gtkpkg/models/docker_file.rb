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
require 'tempfile'
require 'pp'

class DockerFile
  
  def initialize(folder)
    @folder = File.join(folder, "docker_files") 
    FileUtils.mkdir @folder unless File.exists? @folder
  end
  
  def build(content)
    sub_folder = File.join(@folder, content['name'].split('/')[2])
    FileUtils.mkdir(sub_folder) unless File.exists? sub_folder
    File.open(File.join( sub_folder, 'Dockerfile'), 'w') do |f|
      f.write('This is temporary')
    end
  end
end