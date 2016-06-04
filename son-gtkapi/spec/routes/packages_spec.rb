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
require File.expand_path '../../spec_helper.rb', __FILE__

RSpec.describe GtkApi, type: :controller do
  include Rack::Test::Methods
  def app() GtkApi end
  
  describe 'GET /packages' do
    describe 'with no (UU)ID given' do
      context 'and with no query parameters,' do
        it 'should call the Package Management Service model with only the default "offset" and "limit" parameters'
      end
      context 'and with query parameters,' do
        it 'should call the Package Management Service model with the exact parameters'
      end
    end
    describe 'with (UU)ID given,' do
      it 'should raise an error if the UUID is invalid'      
      context 'and with no query parameters,' do
        it 'should call the Package Management Service model with the UUID parameter'
      end
      context 'and with query parameters,' do
        it 'should call the Package Management Service model with only the UUID parameter'
      end
    end
    describe 'with may packages found' do
      it 'should return a package list'
    end    
    describe 'with only one package found' do
      it 'should return a package file'
    end
  end
  
  describe 'POST /packages' do
    context 'with a valid request' do
      it 'should return the package meta-data'
    end
    context 'with repeated package' do
      it 'should return a duplicated package error'
    end
    context 'with invalid request' do
      it 'should return an error'
    end
  end
end
