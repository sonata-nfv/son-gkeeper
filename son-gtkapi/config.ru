require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'rack/parser'
require File.expand_path '../app.rb', __FILE__

# https://github.com/sinatra/sinatra-recipes/blob/ecc597b3725bb9eb7ac9e30a89f72b0d9b0c9af5/middleware/rack_parser.md
use Rack::Parser, :content_types => {
  'application/json' => Proc.new { |body| ::MultiJson.decode body }
}

run Sinatra::Application
