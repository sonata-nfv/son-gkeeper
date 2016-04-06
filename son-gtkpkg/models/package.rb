## SONATA - Gatekeeper
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
require 'tempfile'
require 'pp'

class Package
  class << self
    def save( filename, io)
      # Save posted file
      
      #file = Tempfile.new(['foo', '.jpg'])
      #begin
      #   ...do something with file...
      #ensure
      #   file.close
      #   file.unlink   # deletes the temp file
      #end
      
      
      save_dir = File.join('tmp', SecureRandom.hex)
      FileUtils.mkdir_p(save_dir) unless File.exists? save_dir
    
      pp "Saving file #{filename} in #{save_dir}"
      File.open(File.join( save_dir, filename), 'wb') do |f|
        f.write(io)
      end
      save_dir
    end
  
    def extract( extract_dir, filename)
      # Extract the zipped file to a directory
      Zip::File.open(File.join(extract_dir, filename), 'rb') do |zip_file|
        # Handle entries one by one
        zip_file.each do |entry|
          # Extract to tmp/
          pp "Extracting #{entry.name}"
          f_path = File.join(extract_dir, entry.name)
          entry.extract(f_path)
        end
      end
    end
  end
end