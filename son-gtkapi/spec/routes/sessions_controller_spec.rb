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
require_relative '../spec_helper'
require 'webmock/rspec'
require 'json'
require 'securerandom'
require 'pp'
require 'rspec/its'
require 'base64'

RSpec.describe GtkApi, type: :controller do
  include Rack::Test::Methods
  def app() GtkApi end

  describe 'POST /api/v2/sessions' do
    let(:now) {Time.now.utc}
    let(:secret) {Base64.strict_encode64('Unknown:None')}
    let(:auth_info) {{username: 'Unknown', password: 'None'}}
    let(:user_spied) {spy('user', username: 'Unknown', session_began_at: now, token: 'abc')}
    let(:user_info) {{uuid: SecuredRandom.uuid, username: user_spied.username}}
    context 'with user name and password given,' do
      context 'and user is authenticated,' do
        before(:each) do
          #allow(user_spied).to receive(:authenticated?).and_return(user_spied)
          #allow(User).to receive(:find_by_name).with(auth_info[:username]).and_return(user_spied)
          allow(User).to receive(:authenticated?).with(Base64.strict_encode64(auth_info[:username]+':'+auth_info[:password])).and_return(user_spied)
          post '/api/v2/sessions/', auth_info.to_json
        end
        it 'returns Ok (200)' do
          expect(last_response.status).to eq(200)
        end
        it 'calls User.authenticated?' do
          expect(User).to have_received(:authenticated?)
        end
      end
      context 'but user is not authenticated,' do
        before(:each) do
          #allow(user_spied).to receive(:authenticated?).and_return(nil)
          #allow(User).to receive(:find_by_name).with(auth_info[:username]).and_return(user_spied)
          allow(User).to receive(:authenticated?).with(Base64.strict_encode64(auth_info[:username]+':'+auth_info[:password])).and_raise(UserNotAuthenticatedError)
          post '/api/v2/sessions/', auth_info.to_json
        end
        it 'calls User.authenticated?' do
          expect(User).to have_received(:authenticated?)
        end
        it 'returns Unauthorized (401)' do
          expect(last_response.status).to eq(401)
        end
      end

    end
    context 'without' do
      it 'user name given returns Unprocessable Entity (400)' do
        post '/api/v2/sessions/', {username: '', password:'None'}.to_json
        expect(last_response.status).to eq(400)
      end
      it 'password given returns Unprocessable Entity (400)' do
        post '/api/v2/sessions/', {username: 'Unknown', secret: ''}.to_json
        expect(last_response.status).to eq(400)
      end
    end
  end
  
  describe 'DELETE /api/v2/sessions/:user_name' do
    let(:secret) {Base64.strict_encode64('Unknown:None')}
    context 'with user name given' do
      let(:auth_info) {{username: 'Unknown', secret: secret}}
      let(:user_spied) {spy('user', uuid: SecureRandom.uuid, session: 'session', username: auth_info[:username])}
      let(:user_info) {{uuid: user_spied.uuid, password: auth_info[:secret]}}
      context 'and found' do
        context 'and is successfully deleted' do
          before(:each) do
            allow(user_spied).to receive(:logout!)
            allow(User).to receive(:find_by_name).with(auth_info[:username]).and_return(user_spied)
            delete '/api/v2/sessions/'+auth_info[:username]
          end
          it 'returns Ok (200)' do
            expect(last_response.status).to eq(200)
          end
          it 'calls user.logout!' do
            expect(user_spied).to have_received(:logout!)
          end
        end
      end
      it 'but not found, returns Not Found (404)' do
        allow(User).to receive(:find_by_name).with(auth_info[:username]).and_return(nil)
        delete '/api/v2/sessions/'+auth_info[:username]
        expect(last_response.status).to eq(404)
      end
    end
    it 'without user name given' do
      post '/api/v2/sessions/', {username: '', secret: secret}.to_json
      expect(last_response.status).to eq(400)
    end
  end
end
# {"username":"test","session_began_at":"2017-04-20 13:05:43 UTC","token":{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIzWk4xSDVIcnNpSW1uQnljLWhUZmhmZVh5cXJvakFMMGR6NUJIZ3lSU2RVIn0.eyJqdGkiOiIyNDNlMTgzNy1kMDU1LTRjNGMtOTljMC0wOGNjZmU4YjBkNjciLCJleHAiOjE0OTI2OTM4NDMsIm5iZiI6MCwiaWF0IjoxNDkyNjkzNTQzLCJpc3MiOiJodHRwOi8vc29uLWtleWNsb2FrOjU2MDEvYXV0aC9yZWFsbXMvc29uYXRhIiwiYXVkIjoiYWRhcHRlciIsInN1YiI6IjRiYjkyMTRkLTFiYzgtNGI4ZC1hNzJhLWY4ZGIwYjdiNGQyMCIsInR5cCI6IkJlYXJlciIsImF6cCI6ImFkYXB0ZXIiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiI0N2VkMTQzMC01NzdlLTRmM2QtYWQ4NS0xZDAyMjllMjNkMmEiLCJhY3IiOiIxIiwiY2xpZW50X3Nlc3Npb24iOiIxZDE4YzBmMy01MTVjLTQ0ZGYtOGQ5Yi1lYzJjMWJjYjAxN2EiLCJhbGxvd2VkLW9yaWdpbnMiOlsiaHR0cDovL2xvY2FsaG9zdDo4MDgxIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJkZXZlbG9wZXIiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sIm5hbWUiOiIiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ0ZXN0IiwiZW1haWwiOiJhQGV4YW1wbGUuY29tIn0.BCmsXvvgZcBVwtQNw7AkxcQuNc34Tg_DcORDGCVvrWWDd72cdSRzdr3P3e7froZ7GSe0-1yaQMcAklyYG7TexrLAGT7_Y0ZqoUL7roQCifQ9o3l9UDJKWmYTrUkdWu1f4awgU_kOM8wVVZ4mKCjIpKUjNGO4HtNeU8NCW8kEjJ9Sel-2iZykYlTnNb0vXzc88Td-K4Beh9_ddeSdB3zZKdcIFFuhEwpesc2rkZ9M7m_T3g7oJrhAfU6Ayvy_QjAeFjFW2KVdJCspcSM9RuW0pzU1LVFN845RzBXX7Ac5BhQTzT_AeQwHTMiiSvbnnoVmk3uSMFcHukzNrXnHblDhtA","expires_in":300,"refresh_expires_in":1800,"refresh_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIzWk4xSDVIcnNpSW1uQnljLWhUZmhmZVh5cXJvakFMMGR6NUJIZ3lSU2RVIn0.eyJqdGkiOiJhOGI5NDcwYS02YTg3LTQyOTAtYTA1ZC1iZTQ5NDY0MjFlOTgiLCJleHAiOjE0OTI2OTUzNDMsIm5iZiI6MCwiaWF0IjoxNDkyNjkzNTQzLCJpc3MiOiJodHRwOi8vc29uLWtleWNsb2FrOjU2MDEvYXV0aC9yZWFsbXMvc29uYXRhIiwiYXVkIjoiYWRhcHRlciIsInN1YiI6IjRiYjkyMTRkLTFiYzgtNGI4ZC1hNzJhLWY4ZGIwYjdiNGQyMCIsInR5cCI6IlJlZnJlc2giLCJhenAiOiJhZGFwdGVyIiwiYXV0aF90aW1lIjowLCJzZXNzaW9uX3N0YXRlIjoiNDdlZDE0MzAtNTc3ZS00ZjNkLWFkODUtMWQwMjI5ZTIzZDJhIiwiY2xpZW50X3Nlc3Npb24iOiIxZDE4YzBmMy01MTVjLTQ0ZGYtOGQ5Yi1lYzJjMWJjYjAxN2EiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiZGV2ZWxvcGVyIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19fQ.GjR0GzW0v2kq8axccqT3Ch_xlVrsFzUnRx0c_39XM7mhbYkBgfQ-NE3ih3o6UPjk-bGlK_PesS3FMrZRJDRAQaWSn2rTM5iAiMSU3WNGYVSQmPTqEGg2SoMuhYmFXhARlGkA5yGJIgVxEvatfIyLhQkzMRLgjMDR4jFc7JFW5XsCVScvVxmRSomKPjelVb53NfeOqlPlHa-uIEJNXmpchdxVFBoFEm89ARPxdZn_zGL1NPckcuK5tTQOcpmvyzEuSA7jebSfi_LfIZ5-MVYh9W2InGy2rrdscwLc1euYuJJfjA3PmEeVLGqPD7v0YmliWPnq4lxx6IEWRbD7LJ5tLQ","token_type":"bearer","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIzWk4xSDVIcnNpSW1uQnljLWhUZmhmZVh5cXJvakFMMGR6NUJIZ3lSU2RVIn0.eyJqdGkiOiIxZGNmZGU5Yi0zZGYyLTQyM2EtYTg4MS05MGVmZWQ0NzA5ODUiLCJleHAiOjE0OTI2OTM4NDMsIm5iZiI6MCwiaWF0IjoxNDkyNjkzNTQzLCJpc3MiOiJodHRwOi8vc29uLWtleWNsb2FrOjU2MDEvYXV0aC9yZWFsbXMvc29uYXRhIiwiYXVkIjoiYWRhcHRlciIsInN1YiI6IjRiYjkyMTRkLTFiYzgtNGI4ZC1hNzJhLWY4ZGIwYjdiNGQyMCIsInR5cCI6IklEIiwiYXpwIjoiYWRhcHRlciIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6IjQ3ZWQxNDMwLTU3N2UtNGYzZC1hZDg1LTFkMDIyOWUyM2QyYSIsImFjciI6IjEiLCJuYW1lIjoiIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdCIsImVtYWlsIjoiYUBleGFtcGxlLmNvbSJ9.ArcvZjBxPQ3tdYpGrXQX_h4A_psMxqAl5jGwFrYm69LnNjoQyYhc-xGKLxivl3fqhirrkX_RuWZKBL3MmzO276H6KZJowxcfJsRNauf2EJXwOy6LXcYNz-AQsc28G3wFWqAq5MrM7F3x0qzkDzM8jdl_QTH-swSnzTb9WuB23Aw_8ZOwtuOXNIMZc17VgyHsJePGgGccTyIRqzj7mOqWP6i9UhAEpjfWB6fLa7Fdtws0FA9CozTWBPGTw_dBkFLkOvHGHO5iQ4XaPQS3kRL0_CrQihht-Pc-Nn-TJsRrGIec1qjBvMrhfO-tUUoE6sc_D000OZg5anrvO-DPFPxQTg","not-before-policy":0,"session_state":"47ed1430-577e-4f3d-ad85-1d0229e23d2a"}}

