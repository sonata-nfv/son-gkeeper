##
## Copyright 2015-2017 Portugal Telecom Inovação/Altice Labs
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
def validate_manifest(manifest, options={})

  schema = File.read(settings.manifest_schema)

  # Get the schema from url if exists
  if manifest.has_key?('$schema')
    begin
      schema = RestClient.get(manifest['$schema']).body
    rescue => e
      remove_leftover(options[:files])
      puts e.response
      halt e.response.code, e.response.body
    end
  end

  # Validate agains the schema
  begin
    JSON::Validator.validate!(schema, manifest.to_json)
  rescue JSON::Schema::ValidationError
    remove_leftover(options[:files])
    logger.error "JSON validation: #{$!.message}"
    halt 400, $!.message + "\n"
  end

  # Validate package_name
  halt 400, 'Package name invalid' unless (manifest['package_name'].downcase == manifest['package_name']) && (manifest['package_name'] =~ /^[a-zA-Z\-\d\s]*$/)
  # Validate package_version
  halt 400, 'Package version format is invalid' unless manifest['package_version'] =~ /\A\d+(?:\.\d+)*\z/
end

def remove_leftover(files)
  files.each do |f|
    logger.info "Removing #{f}"
    FileUtils.rm_rf(f)
  end
end

def json_error(code, message)
  content_type :json
  msg = {'error' => message}
  logger.error msg.to_s
  halt code, {'Content-Type'=>'application/json'}, msg.to_json
end

def valid?(uuid)
  uuid.match /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
  uuid == $&
end

def normalize_filename(original)
  return original['filename'] if original.has_key? 'filename'
  return original[:filename] if original[:filename]
  ''
end