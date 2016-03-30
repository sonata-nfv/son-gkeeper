require 'json' 
require 'pp'

class Gtkpkg < Sinatra::Application

  # Receive the Java package
  post '/packages/?' do
    # Save posted file
    filename = 'tmp/' + SecureRandom.hex
    logger.info "Saving file #{filename}"
    File.open(filename, 'w') do |f|
      f.write(request.body.read)
    end

    # Extract the zipped file to a directory
    extract_dir = 'tmp/' + SecureRandom.hex
    Zip::File.open(filename) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to tmp/
        logger.info "Extracting #{entry.name}"
        f_path = File.join(extract_dir, entry.name)
        entry.extract(f_path)
      end
    end

    # Validate Manifest dir and file existance
    halt 400, 'META-INF directory not found' unless File.directory?(extract_dir + '/META-INF')
    halt 400, 'MANIFEST.MF file not found' unless File.file?(extract_dir + '/META-INF/MANIFEST.MF')
    # Validate Manifest fields
    validate_manifest(YAML.load_file(extract_dir + '/META-INF/MANIFEST.MF'), files: [filename, extract_dir])

    remove_leftover([filename, extract_dir])

    #TODO: Send package to catalog
    body =   { 
      'uuid'=> "dcfb1a6c-770b-460b-bb11-3aa863f84fa0", 
      'descriptor_version' => "1.0", 'package_group' => "eu.sonata-nfv.package", 
      'package_name' => "simplest-example", 'package_version' => "0.1", 
      'package_maintainer' => "Michael Bredel, NEC Labs Europe"
    }
    # TODO: URL should be absolute
    halt 201, {'Location' => "/packages/#{body['uuid']}"}, body.to_json
  end
  
  get '/packages/:uuid' do
    pp params['uuid']
    json_error 400, 'Invalid Package UUID' unless valid? params['uuid']
    
    # TODO: grab package info from Catalogue
    
    content_type :son
    #   send_file(file, :disposition => 'attachment', :filename => File.basename(file))
    send_file('spec/fixtures/simplest-example.son', :disposition => 'inline', :type => :son)
  end

end
