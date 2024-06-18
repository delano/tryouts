Gem::Specification.new do |s|
  s.name        = "tryouts"
  s.version     = "2.2.0"
  s.summary     = "Ruby tests that read like documentation."
  s.description = "A simple test framework for Ruby code that uses introspection to allow defining checks in comments."
  s.author      = "Delano Mandelbaum"
  s.email       = "gems@solutious.com"
  s.homepage    = "https://github.com/delano/tryouts"
  s.license     = "MIT"  # replace with actual license

  s.files = Dir["{lib,exe}/**/*", "LICENSE.txt", "README.md"]  # Include the exe folder
  s.bindir = 'exe'  # Specify that executables are in the exe folder
  s.executables = Dir.chdir('exe'){ Dir['*'] }.select { |f| File.file?("exe/#{f}") }

  s.required_ruby_version = Gem::Requirement.new(">= 2.7.8")
end
