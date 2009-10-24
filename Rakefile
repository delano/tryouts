require 'rake/rdoctask'
begin
  require 'yard'
rescue LoadError, RuntimeError
end

# --------------------------------------------------
# Gem
# --------------------------------------------------
def gemspec
  require 'lib/harmony_unit'

  @gemspec ||= Gem::Specification.new do |s|
    s.name                = ""
    s.summary             = ""
    s.description         = ""
    s.author              = ""
    s.email               = ""
    s.homepage            = ""
    s.rubyforge_project   = ""
    s.has_rdoc            =  true
    s.require_path        = "lib"
    s.version             =  NoFW::VERSION
    s.files               =  File.read("Manifest").strip.split("\n")

    s.add_development_dependency 'minitest'
  end
end

desc "Create a Ruby GEM package with the given name and version."
task(:gem) do
  file = Gem::Builder.new(gemspec).build
  FileUtils.mkdir 'pkg/' unless File.directory? 'pkg'
  FileUtils.mv file, "pkg/#{file}", :verbose => true
end

desc "Create gemspec file"
task(:gemspec) do
  open("#{gemspec.name}.gemspec", 'w') {|f| f << YAML.dump(gemspec) }
end

# --------------------------------------------------
# Tests
# --------------------------------------------------
namespace(:test) do

  def run_with(version, cmd)
    puts cmd if ENV['VERBOSE']
    system <<-BASH
      bash -c "source ~/.rvm/scripts/rvm; rvm use #{version}; #{cmd}"
    BASH
  end

  desc "Run all tests"
  task(:all) do
    tests = Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
    cmd = "ruby -rubygems -Ilib -e'%w( #{tests.join(' ')} ).each {|file| require file }'"
    run_with('jruby -v 1.4.0RC1', cmd)
  end

  desc "Run all tests on multiple ruby versions (requires rvm with 1.8.6 and 1.8.7)"
  task(:portability) do
    versions = %w( 1.8.6  1.8.7 )
    versions.each do |version|
      system <<-BASH
        bash -c 'source ~/.rvm/scripts/rvm;
                 rvm use #{version};
                 echo "--------- `ruby -v` ----------\n";
                 rake -s test:all'
      BASH
    end
  end
end

# --------------------------------------------------
# Docs
# --------------------------------------------------
desc "Generate rdoc documentation."
Rake::RDocTask.new(:rdoc => 'rdoc', :clobber_rdoc => 'rdoc:clean', :rerdoc => 'rdoc:force') { |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.title    = ""
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('TODO.txt')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

if defined? YARD
  YARD::Rake::YardocTask.new do |t|
    t.files   = %w( lib/**/*.rb )
    t.options = %w( -o doc/yard --readme README.rdoc --files LICENSE,TODO.txt )
  end
end
