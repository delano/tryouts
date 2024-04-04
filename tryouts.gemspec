Gem::Specification.new do |s|
  s.name        = "tryouts"
  s.version     = "2.2.0-RC1"
  s.summary     = "Don't waste your time writing tests"
  s.description = s.summary
  s.author      = "Delano Mandelbaum"
  s.email       = "delano@solutious.com"
  s.homepage    = "http://github.com/delano/tryouts"
  s.license     = "MIT"  # replace with actual license

  s.files = Dir["{lib,bin}/**/*", "LICENSE.txt", "README.rdoc", "Rakefile"]
  s.executables = ["try"]

  s.add_dependency 'sysinfo', '0.9.0.pre.RC1'

  s.required_ruby_version = '>= 3.1'
end
