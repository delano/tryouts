
class Tryouts; module CLI
  
# = Run
#
# The logic bin/tryouts uses for running tryouts. 
class Run < Drydock::Command

  def init
    @tryouts_globs = [GYMNASIUM_GLOB, File.join(Dir.pwd, '*_tryouts.rb')]
  end
  
  # $ sergeant dreams [path/2/tryouts]
  # Display the dreams from all known tryouts
  def dreams
    load_available_tryouts_files
    if Tryouts.verbose > 0
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
  
  # $ sergeant run [path/2/tryouts]
  # Executes all tryouts that can be found from the current working directory. 
  def run
    start = Time.now
    
    Tryouts.enable_debug if Drydock.debug?
    Tryouts.verbose = @global.quiet ? -1 : @global.verbose

    if Tryouts.verbose > 0
      print "Tryouts #{Tryouts::VERSION} -- "
      print "#{Tryouts.sysinfo.to_s} (#{RUBY_VERSION}) -- "
      puts "#{start.strftime("%Y-%m-%d %H:%M:%S")}"
      puts
    end
    
    load_available_tryouts_files
    
    passed, failed = 0, 0
    Tryouts.instances.each_pair do |group,tryouts_inst|
      puts ' %-79s'.att(:reverse) % group  unless Tryouts.verbose < 0
      puts "  #{tryouts_inst.paths.join("\n  ")}" if Tryouts.verbose > 0
      tryouts_inst.tryouts.each_pair do |name,to|
        begin
          to.run
          to.report
        rescue SyntaxError, LoadError, Exception, TypeError,
               RuntimeError, NoMethodError, NameError => ex
          tryouts_inst.errors << ex
        end
        STDOUT.flush
        passed += to.passed
        failed += to.failed
      end

      unless tryouts_inst.errors.empty?
        title = '%-78s' % " RUNTIME ERRORS !?"
        puts $/, ' ' << title.color(:red).att(:reverse).bright
        tryouts_inst.errors.each do |ex|
          
          puts '%4s%s: %s' % ['', ex.class, ex.message.to_s.split($/).join($/ + ' '*16)]
          puts

          if [SyntaxError].member? ex.class
            # don't print anymore. 
          else
            unless ex.backtrace.nil?
              trace = Tryouts.verbose > 1 ? ex.backtrace : [ex.backtrace.first]
              puts '%14s  %s' % ["", trace.join($/ + ' '*16)]
              puts 
            end
          end
        end
      end
    end
    
    if Tryouts.verbose < 0
      if (passed == 0 && failed == 0)
        exit -1
      elsif failed == 0 && !Tryouts.failed?
        puts "PASS"
        exit 0
      else
        puts "FAIL"
        exit 1
      end
    else
      if Tryouts.verbose > 0
        elapsed = Time.now - start
        puts $/, "  Elapsed: %.3f seconds" % elapsed.to_f #if elapsed > 0.01
      end
      if (passed == 0 && failed == 0)
        puts DEV if Tryouts.verbose > 4
        msg = " You didn't even try to acheive your dreams :[ "
        puts $/, msg.att(:reverse)
        exit -1
      elsif failed == 0 && !Tryouts.failed?
        puts PUG if Tryouts.verbose > 4
        msg = passed > 1 ? "All %s dreams" : "Your only dream"
        msg = (" #{msg} came true " % [passed+failed]).color(:green)
        puts $/, msg.att(:reverse)
        exit 0
      else
        puts BUG if Tryouts.verbose > 4
        score = (passed.to_f / (passed.to_f+failed.to_f)) * 100
        msg = " %s of %s dreams came true (%d%%) ".color(:red)
        msg = msg % [passed, passed+failed, score.to_i]
        puts $/, msg.att(:reverse)
        exit 1
      end
      
    end
  end
  
  # $ sergeant list 
  # Displays all known tryouts from the current working directory
  def list
    load_available_tryouts_files
    Tryouts.instances.each_pair do |n,tryouts_inst|
      puts n
      if Tryouts.verbose > 0
        puts "  #{tryouts_inst.paths.join("\n  ")}"
      end
      tryouts_inst.tryouts.each_pair do |t2,tryout|
        puts "  " << tryout.name
        tryout.drills.each do |drill|
          puts "    " << drill.name
        end
      end
    end
  end
  
private 

  # Find and load all tryouts files
  def load_available_tryouts_files
    @tryouts_files = []
    # If file paths were given, check those only. 
    unless @argv.empty?
      @argv.each do |file|
        unless File.exists?(file)
          raise Tryouts::Exception, "Not found: #{file}"
        end
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
    @tryouts_files.each { |f| puts "LOADING: #{f}"} if Tryouts.verbose > 1
    @tryouts_files.each { |file| Tryouts.parse_file file }
  end
end
end; end

class Tryouts::CLI::Run
  DEV = %q{
          ^^             @@@@@@@@@
     ^^       ^^      @@@@@@@@@@@@@@@
                    @@@@@@@@@@@@@@@@@@              ^^
                   @@@@@@@@@@@@@@@@@@@@
   ~~~ ~~~~~~~~ ~~ &&&&&&&&&&&&&&&&&&&& ~~~~~~~ ~~~~~~~~~~~ ~~
   ~~   ~  ~       ~~~~~~~~~~~~~~~~~~~~ ~       ~~     ~~ ~
   ~      ~~ ~~ ~~  ~~~~~~~~~~~~~ ~~~~  ~     ~~~    ~ ~~~  ~
     ~         ~      ~~~~~~  ~~ ~~~       ~~ ~ ~~  ~~ ~
    ~ ~      ~           ~~ ~~~~~~  ~      ~~  ~           ~~~
             ~        ~      ~      ~~   ~             ~
  }
  BUG = %q{
     ,--.____                                     ____.--.
    /  .'.'"``--...----------.___.----------...--''"`.`.  \
    | .'.'         .                       .         `.`. |
    `. .'|     . ' - . _    `-----'    _ . - ' .     |`. .'
     `.' `|   .'   _     "-._     _.-"     _   `.   |' `.'
          |  |        " -.           .- "        |  |
           \|        ;;..  "|i. .i|"  ..;;        |/
           `|      ,---.``.   ' '   .'',---.      |'        
            |    <'(__.'>.'---` '---`.<`.__)`>    | 
            |   `. `~  .'  ,-------.  `.  ~'.'    |
            |  |=_"`=.'  . `-.___.-' .  `.='"_=|  |
            |  |  ==/  : ` :   i   : ' :  \==  |  |
            |  | ==/      /\___|___/\      \== |  |
             `.| =Y      .' """_""" `.      Y= |.'
               L ||      ;  .=="==.  ;      || J 
                \ ;     .' '       ` `.     ; /
                 `.     ;             ;     .'
                  ;    ;'\           /`;    ;
                  `;  .'.'/.       ,\`.`.  ;' 
                   `-=;_-'  `-----'  `-_;=-'        -bodom-
}
  PUG = %q{
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
                      \   \      `-^-|     |   / , ,\ 
                       )  )          | -^- ;   `-^-^' 
                    _,' _ ;          |    | 
                   / , , ,'         /---. : 
                   `-^-^'          (  :  :,'    
                                    `-^--'          -hrr- 
}
end
