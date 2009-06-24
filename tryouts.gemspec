@spec = Gem::Specification.new do |s|
	s.name = "tryouts"
  s.rubyforge_project = "tryouts"
	s.version = "0.6.2"
	s.summary = "Tryouts are high-level tests for your Ruby code. May all your dreams come true!"
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
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt]
  
  # Update --main to reflect the default page to display
  s.rdoc_options = ["--line-numbers", "--title", "Tryouts: #{s.summary}", "--main", "README.rdoc"]
  
  # = DEPENDENCIES =
  # Add all gem dependencies
  s.add_dependency 'drydock', '>= 0.6.5'
  s.add_dependency 'rye', '>= 0.8.2'
  s.add_dependency 'sysinfo', '>= 0.5.1'
  
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
  lib/tryouts/drill/response.rb
  lib/tryouts/drill/sergeant/api.rb
  lib/tryouts/drill/sergeant/cli.rb
  lib/tryouts/mixins.rb
  lib/tryouts/mixins/hash.rb
  lib/tryouts/orderedhash.rb
  lib/tryouts/tryout.rb
  tryouts.gemspec
  )
  
  s.has_rdoc = true
  s.rubygems_version = '1.3.0'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<RedCloth>, [">= 4.0.4"])
    else
      s.add_dependency(%q<RedCloth>, [">= 4.0.4"])
    end
  else
    s.add_dependency(%q<RedCloth>, [">= 4.0.4"])
  end
  
end