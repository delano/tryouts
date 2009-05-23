
module Tryouts::CLI
  class Run < Drydock::Command

    def init
      @tryouts_globs = [GYMNASIUM_GLOB, File.join(Dir.pwd, '*_tryouts.rb')]
    end
    
    def dreams
      load_available_tryouts_files
      puts Tryouts.dreams.to_yaml
    end
    
    def run
      load_available_tryouts_files
      Tryouts.run
    end
    
    
  private 
    def load_available_tryouts_files
      if @argv.files
        @argv.files.each do |file|
          file = File.join(file, '**', '*_tryouts.rb') if File.directory?(file)
          @tryouts_globs += file
        end
      end

      @tryouts_files = []
      @tryouts_globs.each do |glob|
        @tryouts_files += Dir.glob glob
      end
      @tryouts_files.uniq!

      puts "FOUND:", @tryouts_files if @global.verbose > 0
      
      @tryouts_files.each { |file| Tryouts.parse_file file }
    end
  end
end