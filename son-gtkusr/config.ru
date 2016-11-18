# config.ru (run with rackup)
# require './app'
require File.expand_path '../main.rb', __FILE__

# run Sinatra::Application
run Rack::URLMap.new({
                         '/' => PublicAPI,
                         '/api' => SecuredAPI,
                         '/keycloak' => Keycloak
                     })