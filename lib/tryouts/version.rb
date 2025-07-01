# lib/tryouts/version.rb

class Tryouts
  module VERSION
    def self.to_s
      version_file
      [@version_file[:MAJOR], @version_file[:MINOR], @version_file[:PATCH]].join('.')
    end
    alias inspect to_s
    def self.version_file
      require 'yaml'
      @version_file ||= YAML.load_file(File.join(TRYOUTS_LIB_HOME, '..', 'VERSION.yml'))
    end
  end
end
