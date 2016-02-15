require 'sinatra/base'

class SonGtkGui < Sinatra::Base
  set :bind, "0.0.0.0"
  get '/' do
    'Hello, SONATA End User!'
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
