@spec = Gem::Specification.new do |s|
	s.name = "tryouts"
  s.rubyforge_project = "tryouts"
	s.version = "0.8.5.001"
	s.summary = "Tryouts is a high-level testing library (DSL) for your Ruby codes and command-line applications."
	s.description = s.summary
	s.author = "Delano Mandelbaum"
	s.email = "tryouts@solutious.com"
	s.homepage = "http://github.com/delano/tryouts"
  
  # = EXECUTABLES =
  # The list of executables in your project (if any). Don't include the path, 
  # just the base filename.
  s.executables = %w[sergeant]
  
  # Directories to extract rdocs from
  s.require_paths = %w[lib]  
  
  # Specific files to include rdocs from
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt CHANGES.txt]
  
  # Update --main to reflect the default page to display
  s.rdoc_options = ["--line-numbers", "--title", "Tryouts: #{s.summary}", "--main", "README.rdoc"]
  
  ## NOTE: this is for Rudy conversion (incomplete)
  ##rdoc '--line-numbers', '--title', "Tryouts: Basketball tryouts for your Ruby codes and command line apps. Go for it!", '--main', 'README.rdoc', 
  
  # = DEPENDENCIES =
  # Add all gem dependencies
  s.add_dependency 'rye'
  s.add_dependency 'attic'
  s.add_dependency 'drydock'
  s.add_dependency 'sysinfo'
  
  # = MANIFEST =
  # The complete list of files to be included in the release. When GitHub packages your gem, 
  # it doesn't allow you to run any command that accesses the filesystem. You will get an
  # error. You can ask your VCS for the list of versioned files:
  # git ls-files
  # svn list -R
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  bin/mockout
  bin/sergeant
  lib/tryouts.rb
  lib/tryouts/cli.rb
  lib/tryouts/cli/run.rb
  lib/tryouts/drill.rb
  lib/tryouts/drill/context.rb
  lib/tryouts/drill/dream.rb
  lib/tryouts/drill/reality.rb
  lib/tryouts/drill/response.rb
  lib/tryouts/drill/sergeant/api.rb
  lib/tryouts/drill/sergeant/benchmark.rb
  lib/tryouts/drill/sergeant/cli.rb
  lib/tryouts/drill/sergeant/rbenchmark.rb
  lib/tryouts/mixins.rb
  lib/tryouts/mixins/hash.rb
  lib/tryouts/orderedhash.rb
  lib/tryouts/stats.rb
  lib/tryouts/tryout.rb
  tryouts.gemspec
  tryouts/01_mixins_tryouts.rb
  tryouts/10_syntax_tryouts.rb
  tryouts/14_set_tryouts.rb
  tryouts/15_dreams_tryouts.rb
  tryouts/20_cli_tryouts.rb
  tryouts/30_benchmark_tryouts.rb
  tryouts/50_class_context_tryouts.rb
  tryouts/standalone_test.rb
  )
  
  s.has_rdoc = true
  s.rubygems_version = '1.3.0'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end
  
end