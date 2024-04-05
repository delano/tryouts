Gem::Specification.new do |s|
  s.name        = "tryouts"
  s.version     = "2.2.0"
  s.summary     = "Don't waste your time writing tests"
  s.description = "Tryouts: #{s.summary}"
  s.author      = "Delano Mandelbaum"
  s.email       = "delano@solutious.com"
  s.homepage    = "http://github.com/delano/tryouts"
  s.license     = "MIT"  # replace with actual license

  s.files = Dir["{lib,bin}/**/*", "LICENSE.txt", "README.rdoc", "Rakefile"]
  s.executables = ["try"]

  s.add_dependency 'sysinfo', '~> 0.10'

  s.required_ruby_version = '>= 2.6.8'
end
