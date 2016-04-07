require 'sinatra'
require 'json'

$packages = [
  { 
    uuid: "53676529-b277-4369-8ff9-8668310eab7d", 
    descriptor_version: "1.0",
    package_group: "eu.sonata-nfv.package",
    package_name: "simplest-example",
    package_version: "0.1",
    package_maintainer: "Michael Bredel, NEC Labs Europe"
  },
  { 
    uuid: "0f4eb013-28b1-4590-b59d-d3f094e168d8", 
    descriptor_version: "1.0",
    package_group: "eu.sonata-nfv.package",
    package_name: "simplest-example",
    package_version: "0.2",
    package_maintainer: "Michael Bredel, NEC Labs Europe"
  }
]

get '/:uuid' do
  content_type :json
  puts params.inspect
  $packages.each do |p|
    puts p.inspect
    return p.to_json if params['uuid'] == p[:uuid]
  end
  {}.to_json
end

get '/' do
  content_type :json
  puts params.inspect
  puts params.size
  if params.size
    selected = []
    $packages.each do |p|
      puts p.inspect
      selected << p if params['vendor'] && p[:package_group] == params['vendor']
      selected << p if params['version'] && p[:package_version] == params['version']
      selected << p if params['name'] && p[:package_name] == params['name']
    end
    selected.to_json
  else
    $packages.to_json
  end
end
