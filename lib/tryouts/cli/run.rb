
module Tryouts::CLI
  class Run < Drydock::Command

    
    def run
      
      tryouts_globs = [GYMNASIUM_GLOB, File.join(Dir.pwd, '*_tryouts.rb')]
      if @argv.files
        @argv.files.each do |file|
          file = File.join(file, '**', '*_tryouts.rb') if File.directory?(file)
          tryouts_globs += file
        end
      end

      tryouts_files = []
      tryouts_globs.each do |glob|
        tryouts_files += Dir.glob glob
      end
      tryouts_files.uniq!

      puts "FOUND:", tryouts_files if @global.verbose > 0

      tryouts_files.each { |file| load file }
      Tryouts.classes.each do |klass|
        klass.run
      end
    
    end
       
  end
end