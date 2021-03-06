require 'rake/file_utils'
require 'yaml'
require 'common/deep_copy'
require 'bosh/stemcell/ami'

module Bosh::Stemcell::Aws
  class LightStemcell
    def initialize(stemcell)
      @stemcell = stemcell
    end

    def write_archive
      stemcell.extract(exclude: 'image') do |extracted_stemcell_dir|
        Dir.chdir(extracted_stemcell_dir) do
          FileUtils.touch('image', verbose: true)

          File.open('stemcell.MF', 'w') do |out|
            Psych.dump(manifest, out)
          end

          Rake::FileUtilsExt.sh("sudo tar cvzf #{path} *")
        end
      end
    end

    def path
      File.join(File.dirname(stemcell.path), "light-#{File.basename(stemcell.path)}")
    end

    private

    attr_reader :stemcell

    def manifest
      ami = Bosh::Stemcell::Ami.new(stemcell)
      ami_id = ami.publish
      manifest = Bosh::Common::DeepCopy.copy(stemcell.manifest)
      manifest['cloud_properties']['ami'] = { ami.region => ami_id }
      manifest
    end
  end
end
