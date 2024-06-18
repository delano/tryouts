Gem::Specification.new do |s|
  s.name        = "tryouts"
  s.version     = "2.2.0"
  s.summary     = "Ruby tests that read like documentation."
  s.description = "A simple test framework for Ruby code that uses introspection to allow defining checks in comments."
  s.author      = "Delano Mandelbaum"
  s.email       = "gems@solutious.com"
  s.homepage    = "https://github.com/delano/tryouts"
  s.license     = "MIT"  # replace with actual license

  s.files = Dir["{lib,bin}/**/*", "LICENSE.txt", "README.rdoc", "Rakefile"]
  s.executables = ["try"]

  s.required_ruby_version = '>= 2.6.8'
end
