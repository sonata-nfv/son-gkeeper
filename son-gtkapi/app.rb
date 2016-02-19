require 'sinatra'
require 'sinatra/activerecord'

class Package < ActiveRecord::Base
  validates_presence_of :name
end
#
# SecureRandom.uuid

class App < Sinatra::Base
  before do
    content_type :json
  end

  get '/' do
    p 'Hello!'
  end

  get '/packages/?' do
    p params.inspect
    @packages = Package.all
    @packages.to_json
  end

  get '/packages/:id/?' do
    @package = Package.find_by_id(params[:id])
    halt 404, "Sorry, couldn't find package \"#{params[:id]}\"." unless @package
    @package.to_json
  end

  post '/packages' do
    @json = JSON.parse(request.body.read)
    p @json
    @package = Package.create!(@json)
    halt 404, "Sorry, couldn't add package \"#{params[:name]}\"." unless @package
    @package.to_json
  end
end

