require 'sinatra'
require 'json'

$functions = [{
    'uuid'=> "0f4eb013-28b1-4590-b59d-d3f094e168d8",
    'created_at'=> Time.now.utc.to_s,
    'updated_at'=> Time.now.utc.to_s,
    "vnf_id"=>"vnf_firewall",
    "vendor"=>"eu.sonata-nfv", 
    "name"=>"firewall-vnf", 
    "version"=>"0.1"
  }]
$packages = [
  {
    "uuid"=> "53676529-b277-4369-8ff9-8668310eab7d", 
    "descriptor_version"=>"1.0",
    "group"=>"eu.sonata-nfv.package",
    "name"=>"sonata-demo",
    "version"=>"0.1.1",
    "maintainer"=>"Michael Bredel, NEC Labs Europe",
    "description"=>"\"The package descriptor for the SONATA demo package that\n comprises the descritors of the demo network service,\n the related VNFs, as well as the virtual machine\n images (or docker files) to instantiate the service.\"\n", "entry_service_template"=>"/service_descriptors/sonata-demo.yml",
    "sealed"=>true,
    "package_content"=>[
      {"name"=>"/service_descriptors/sonata-demo.yml", "content-type"=>"application/sonata.service_descriptor", "md5"=>"a16ce1b66bd6d6916c8f994efca0d778" },
      {"name"=>"/function_descriptors/iperf-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"f70587f5f8cbdb60d79a4446a993c8de"},
      {"name"=>"/function_descriptors/firewall-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"d6c6fc264c5278fb1ccccaa6bdc4e64a"},
      {"name"=>"/function_descriptors/tcpdump-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"ef085df7c17eb65e25dbe0979de06920"},
      {"name"=>"/docker_files/iperf/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"5bea7b1f2f73803946674adecaaa9246"},
      {"name"=>"/docker_files/firewall/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"fed89e35d173e6aeaf313e1a9ab3f552"},
      {"name"=>"/docker_files/tcpdump/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"e0d2bb965744161ffb0f8af459a589e3"}
    ],
    "artifact_dependencies"=>[
      {
        "name"=>"my-vm-image",
        "url"=>"http://www.bredel-it.de/path/to/vm-image",
        "md5"=>"00236a2ae558018ed13b5222ef1bd9f3",
        "credentials"=>{"username"=>"username", "password"=>"password"}
      }
    ],
    'created_at'=> Time.now.utc.to_s,
    'updated_at'=> Time.now.utc.to_s
  },
  { 
    'uuid'=> "0f4eb013-28b1-4590-b59d-d3f094e168d8", 
    "descriptor_version"=>"1.0",
    "vendor"=>"eu.sonata-nfv.package",
    "name"=>"sonata-demo",
    "version"=>"0.1.2",
    "maintainer"=>"Michael Bredel, NEC Labs Europe",
    "description"=>"\"The package descriptor for the SONATA demo package that\n comprises the descritors of the demo network service,\n the related VNFs, as well as the virtual machine\n images (or docker files) to instantiate the service.\"\n", "entry_service_template"=>"/service_descriptors/sonata-demo.yml",
    "sealed"=>true,
    "package_content"=>[
      {"name"=>"/service_descriptors/sonata-demo.yml", "content-type"=>"application/sonata.service_descriptor", "md5"=>"a16ce1b66bd6d6916c8f994efca0d778" },
      {"name"=>"/function_descriptors/iperf-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"f70587f5f8cbdb60d79a4446a993c8de"},
      {"name"=>"/function_descriptors/firewall-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"d6c6fc264c5278fb1ccccaa6bdc4e64a"},
      {"name"=>"/function_descriptors/tcpdump-vnfd.yml", "content-type"=>"application/sonata.function_descriptor", "md5"=>"ef085df7c17eb65e25dbe0979de06920"},
      {"name"=>"/docker_files/iperf/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"5bea7b1f2f73803946674adecaaa9246"},
      {"name"=>"/docker_files/firewall/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"fed89e35d173e6aeaf313e1a9ab3f552"},
      {"name"=>"/docker_files/tcpdump/Dockerfile", "content-type"=>"application/sonata.docker_files", "md5"=>"e0d2bb965744161ffb0f8af459a589e3"}
    ],
    "artifact_dependencies"=>[
      {
        "name"=>"my-vm-image",
        "url"=>"http://www.bredel-it.de/path/to/vm-image",
        "md5"=>"00236a2ae558018ed13b5222ef1bd9f3",
        "credentials"=>{"username"=>"username", "password"=>"password"}
      }
    ],
    'created_at'=> Time.now.utc.to_s,
    'updated_at'=> Time.now.utc.to_s
  }
]
$services = [
  {
    "descriptor_version"=>"1.0", 
    "vendor"=>"eu.sonata-nfv.service-descriptor", 
    "name"=>"sonata-demo", 
    "version"=>"0.1", 
    "author"=>"Sonata, sonata-nfv", 
    "description"=>"\"The network service descriptor for the SONATA demo,\n comprising iperf, a firewall, and tcpump.\"\n", 
    "network_functions"=>[{
      "vnf_id"=>"vnf_firewall",
      "vendor"=>"eu.sonata-nfv", 
      "name"=>"firewall-vnf", 
      "version"=>"0.1"
    }],
    "connection_points"=>[
      {"id"=>"ns:mgmt", "type"=>"interface"}, 
      {"id"=>"ns:input", "type"=>"interface"}, 
      {"id"=>"ns:output", "type"=>"interface"}
    ], 
    "virtual_links"=>[
      {"id"=>"mgmt", "connectivity_type"=>"E-LAN", "connection_points_reference"=>["vnf_firewall:mgmt", "ns:mgmt"]}, 
      {"id"=>"input", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_firewall:input", "ns:input"]}, 
      {"id"=>"output", "connectivity_type"=>"E-Line", "connection_points_reference"=>["vnf_firewall:output", "ns:output"]}
    ], 
    "forwarding_graphs"=>[
      {
        "fg_id"=>"ns:fg01", 
        "number_of_endpoints"=>2, 
        "number_of_virtual_links"=>2, 
        "constituent_vnfs"=>["vnf_firewall"], 
        "network_forwarding_paths"=>[
          {"fp_id"=>"ns:fg01:fp01", "policy"=>"none", "connection_points"=>[
            {"connection_point_ref"=>"ns:input", "position"=>1}, 
            {"connection_point_ref"=>"vnf_firewall:input", "position"=>2}, 
            {"connection_point_ref"=>"vnf_firewall:output", "position"=>3}, 
            {"connection_point_ref"=>"ns:output", "position"=>4}
          ]}
        ]
      }],
    'status'=> 'OK',
    'created_at'=> Time.now.utc.to_s,
    'updated_at'=> Time.now.utc.to_s,
    'uuid'=> "15eb8a1c-ebf4-4d6d-878c-c4a55cfadb7e"
  }
]

get '/catalogues/packages/:uuid' do
  content_type :json
  puts params.inspect
  $packages.each do |p|
    puts p.inspect
    return p.to_json if params['uuid'] == p['uuid']
  end
  {}.to_json
end

get '/catalogues/packages' do
  content_type :json
  ['offset', 'limit'].each do |p|
    params.delete(p) 
  end
  unless params.empty?
    puts "With params #{params}"
    selected = []
    $packages.each do |p|
      puts p.inspect
      selected << p if params['uuid'] && p['uuid'] == params['uuid']
      selected << p if params['vendor'] && p['vendor'] == params['vendor']
      selected << p if params['version'] && p['version'] == params['version']
      selected << p if params['name'] && p['name'] == params['name']
    end
    selected.to_json
  else
    puts "With no params"
    $packages.to_json
  end
end

get '/catalogues/network-services/?' do
  content_type :json
  puts "With params #{params}: "
  params.delete("offset") #if params.has_key? "offset"
  params.delete("limit") #if params.has_key? "limit"
  unless params.empty?
    puts "With params #{params}: "
    selected = []
    $services.each do |s|
      puts "service #{s.inspect}"
      selected << s if params['vendor'] && s['vendor'] == params['vendor']
      selected << s if params['version'] && s['version'] == params['version']
      if params['name'] && s['name'] == params['name']
        selected << s
        puts "name = "+params['name']
      end
    end
    puts "selected: #{selected}"
    selected.to_json
  else
    puts "With no params: "
    $services.to_json
  end
end

get '/catalogues/vnfs/?' do
  content_type :json
  halt 200, $functions.to_json
end

get '/catalogues/vnfs/:uuid' do
  content_type :json
  halt 200, $functions[0].to_json
end

get '/catalogues/network-services/:uuid' do
  content_type :json
  puts "In GET /catalogues/network-services/#{params[:uuid]}"
  $services.each do |s|
    puts s.inspect
    if params['uuid'] == s['uuid']
      puts "In GET /catalogues/network-services/#{params[:uuid]}: found service #{s.inspect}"
      return s.to_json 
    end
  end
  {}.to_json
end

post '/catalogues/vnfs' do
  puts "FakeCatalogue POST /catalogues/vnfs Content-Type: "+request.content_type
  halt 415 unless request.content_type == 'application/json'
  function_d = JSON.parse(request.body.read)
  if function_d
    puts "FakeCatalogue POST /catalogues/vnfs function_d=#{function_d}"
    function = function_d.merge({ 'uuid'=>SecureRandom.uuid, 'created_at'=> Time.now.utc.to_s, 'updated_at'=> Time.new.utc.to_s})
    $functions << function
    halt 201, function.to_json
  else
    halt 400, 'No function provided'
  end
end

post '/catalogues/network-services' do
  puts "FakeCatalogue POST /catalogues/network-services Content-Type: "+request.content_type
  halt 415 unless request.content_type == 'application/json'
  service_d = JSON.parse(request.body.read)
  if service_d
    puts "FakeCatalogue POST /catalogues/network-services service_d=#{service_d}"
    service = service_d.merge({ 'uuid'=>SecureRandom.uuid, 'created_at'=> Time.now.utc.to_s, 'updated_at'=>Time.new.utc.to_s})
    $services << service
    halt 201, service.to_json
  else
    halt 400, 'No service provided'
  end
end

post '/catalogues/packages' do
  puts "FakeCatalogue POST /catalogues/packages\n\tContent-Type: "+request.content_type
  halt 415 unless request.content_type == 'application/json'
  package = JSON.parse(request.body.read)
  if package
    puts "\tpackage=#{package}"
    package.merge!({ 'uuid'=>SecureRandom.uuid, 'created_at'=> Time.now.utc.to_s, 'updated_at'=>Time.new.utc.to_s})
    puts "\tpackage=#{package}"
    $packages << package
    halt 201, package.to_json
  else
    halt 400, 'No package provided'
  end
end
