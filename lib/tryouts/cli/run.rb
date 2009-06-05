
class Tryouts; module CLI
  
  # = Run
  #
  # The logic bin/tryouts uses for running tryouts. 
  class Run < Drydock::Command

    def init
      @tryouts_globs = [GYMNASIUM_GLOB, File.join(Dir.pwd, '*_tryouts.rb')]
    end
    
    def dreams
      load_available_tryouts_files
      if @global.verbose > 0
        puts Tryouts.dreams.to_yaml
      else
        Tryouts.dreams.each_pair do |n,dreams|
          puts n
          dreams.each_pair do |n, dream|
            puts "  " << n
            dream.each_pair do |n, drill|
              puts "    " << n
            end
          end
        end
      end
    end
    
    def run
      load_available_tryouts_files
      Tryouts.run
    end
    
    def list
      load_available_tryouts_files
      if @global.verbose > 0
        puts Tryouts.instances.to_yaml
      else
        Tryouts.instances.each_pair do |n,tryouts|
          puts n
          tryouts.tryouts.each do |tryout|
            puts "  " << tryout.name
            tryout.drills.each do |drill|
              puts "    " << drill.name
            end
          end
        end
      end
    end
    
  private 
    def load_available_tryouts_files
      @tryouts_files = []
      
      if @argv.files
        @argv.files.each do |file|
          file = File.join(file, '**', '*_tryouts.rb') if File.directory?(file)
          @tryouts_files += Dir.glob file
        end
      else
        @tryouts_globs.each do |glob|
          @tryouts_files += Dir.glob glob
        end
      end
      
      @tryouts_files.uniq!

      puts "FOUND:", @tryouts_files if @global.verbose > 0
      
      @tryouts_files.each { |file| Tryouts.parse_file file }
    end
  end
end; end