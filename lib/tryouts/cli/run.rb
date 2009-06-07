
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
    if @global.verbose > 0
      puts "#{Tryouts.sysinfo.to_s} (#{RUBY_VERSION})"
    end
    
    load_available_tryouts_files

    passed, failed = 0, 0
    Tryouts.instances.each_pair do |group,tryouts_inst|
      puts '', ' %-60s'.att(:reverse) % group
      puts "  #{tryouts_inst.paths.join("\n  ")}" if @global.verbose > 0
      tryouts_inst.tryouts.each_pair do |name,to|
        to.run
        to.report
        STDOUT.flush
        passed += to.passed
        failed += to.failed
      end
    end
    unless @global.quiet
      if failed == 0
        puts MOOKIE if @global.verbose > 4
        msg = " All %s dreams came true ".att(:reverse).color(:green)
        msg = msg % [passed+failed]
      else
        score = (passed.to_f / (passed.to_f+failed.to_f)) * 100
        msg = " %s of %s dreams came true (%d%%) ".att(:reverse).color(:red)
        msg = msg % [passed, passed+failed, score.to_i]
      end
      puts $/, msg
    end
  end
  
  def list
    load_available_tryouts_files
    ##if @global.verbose > 2
    ##  puts Tryouts.instances.to_yaml   # BUG: Raises "can't dump anonymous class Class"
    ##else
      Tryouts.instances.each_pair do |n,tryouts_inst|
        puts n
        if @global.verbose > 0
          puts "  #{tryouts_inst.paths.join("\n  ")}"
        end
        tryouts_inst.tryouts.each_pair do |t2,tryout|
          puts "  " << tryout.name
          tryout.drills.each do |drill|
            puts "    " << drill.name
          end
        end
      end
    ##end
  end
  
private 
  def load_available_tryouts_files
    @tryouts_files = []
    # If file paths were given, check those only. 
    unless @argv.empty?
      @argv.each do |file|
        file = File.join(file, '**', '*_tryouts.rb') if File.directory?(file)
        @tryouts_files += Dir.glob file
      end
    # Otherwise check the default globs
    else
      @tryouts_globs.each do |glob|
        @tryouts_files += Dir.glob glob
      end
    end
    @tryouts_files.uniq!  # Don't load the same file twice
    @tryouts_files.each { |f| puts "LOADING: #{f}"} if @global.verbose > 0
    @tryouts_files.each { |file| Tryouts.parse_file file }
  end
end
end; end

MOOKIE = %q{
      __,-----._                       ,-. 
    ,'   ,-.    \`---.          ,-----<._/ 
   (,.-. o:.`    )),"\\\-._    ,'         `. 
  ('"-` .\       \`:_ )\  `-;'-._          \ 
 ,,-.    \` ;  :  \( `-'     ) -._     :   `: 
(    \ `._\\\ ` ;             ;    `    :    ) 
 \`.  `-.    __   ,         /  \        ;, ( 
  `.`-.___--'  `-          /    ;     | :   | 
    `-' `-.`--._          '           ;     | 
          (`--._`.                ;   /\    | 
           \     '                \  ,  )   : 
           |  `--::----            \'   ;  ;| 
           \    .__,-      (        )   :  :| 
            \    : `------; \      |    |   ; 
             \   :       / , )     |    |  ( 
    -hrr-     \   \      `-^-|     |   / , ,\ 
               )  )          | -^- ;   `-^-^' 
            _,' _ ;          |    | 
           / , , ,'         /---. : 
           `-^-^'          (  :  :,' 
                            `-^--' 
}