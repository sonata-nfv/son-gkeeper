require 'sinatra'
require 'json'

$packages = [
  {
    "uuid"=> "53676529-b277-4369-8ff9-8668310eab7d", 
    "descriptor_version"=>"1.0",
    "package_group"=>"eu.sonata-nfv.package",
    "package_name"=>"sonata-demo",
    "package_version"=>"0.1.1",
    "package_maintainer"=>"Michael Bredel, NEC Labs Europe",
    "package_description"=>"\"The package descriptor for the SONATA demo package that\n comprises the descritors of the demo network service,\n the related VNFs, as well as the virtual machine\n images (or docker files) to instantiate the service.\"\n", "entry_service_template"=>"/service_descriptors/sonata-demo.yml",
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
    "package_group"=>"eu.sonata-nfv.package",
    "package_name"=>"sonata-demo",
    "package_version"=>"0.1.2",
    "package_maintainer"=>"Michael Bredel, NEC Labs Europe",
    "package_description"=>"\"The package descriptor for the SONATA demo package that\n comprises the descritors of the demo network service,\n the related VNFs, as well as the virtual machine\n images (or docker files) to instantiate the service.\"\n", "entry_service_template"=>"/service_descriptors/sonata-demo.yml",
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
  puts params.inspect
  puts params.size
  if params.size
    selected = []
    $packages.each do |p|
      puts p.inspect
      selected << p if params['vendor'] && p['package_group'] == params['vendor']
      selected << p if params['version'] && p['package_version'] == params['version']
      selected << p if params['name'] && p['package_name'] == params['name']
    end
    selected.to_json
  else
    $packages.to_json
  end
end
