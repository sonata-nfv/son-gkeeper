require 'json'
require 'sinatra'
require_relative '../helpers/init'

class Keycloak < Sinatra::Application

  post '/register' do
    registration
  end

  post '/login' do
    username = params[:username]
    password = params[:password]

    credentials = {"type" => "password", "value" => password.to_s}
    login(username, credentials)
  end

  post '/auth' do
    # TODO: implement authentication API
  end

  post '/authorize' do
    authorize
  end

  post '/userinfo' do
    # TODO: implement userinfo API
  end

  post '/logout' do
    logout
  end
end

class SecuredAPI < Sinatra::Application
  # This is a sample of a secured API

  get '/services' do
    # content_type :json
    # {message: "Hello, User!"}.to_json

    # scopes, user = request.env.values_at :scopes, :user
    # username = user['username'].to_sym

    # if scopes.include?('view_services') && @accounts.has_key?(username)
    # content_type :json
    # { services: @accounts[username]}.to_json
    # else
    # halt 403

    process_request request, 'view_services' do |req, username|
      content_type :json
      {services: @accounts[username]}.to_json
    end
  end

  post '/services' do
    # code
    scopes, user = request.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?('add_services') && @accounts.has_key?(username)
      service = request[:service]
      @accounts[username] << {'Service' => service}

      content_type :json
      {services: @accounts[username]}.to_json
    else
      halt 403
    end
  end

  delete '/services' do
    # code
    scopes, user = request.env.values_at :scopes, :user
    username = user['username'].to_sym

    if scopes.include?('remove_services') && @accounts.has_key?(username)
      service = request[:service]

      @accounts[username].delete_if { |h| h['Service'] == service }

      content_type :json
      {services: @accounts[username]}.to_json
    else
      halt 403
    end
  end
end

class PublicAPI < Sinatra::Application
  # This is a sample of a public API

  post '/login' do
    username = params[:username]
    password = params[:password]

    if @logins[username.to_sym] == password
      content_type :json
      {token: token(username)}.to_json
    else
      halt 401
    end
  end
end
