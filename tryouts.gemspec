require_relative 'lib/tryouts'

Gem::Specification.new do |spec|
  spec.name        = 'tryouts'
  spec.version     = Tryouts::VERSION
  spec.summary     = 'Ruby tests that read like documentation.'
  spec.description = 'A simple test framework for Ruby code that uses introspection to allow defining checks in comments.'
  spec.author      = 'Delano Mandelbaum'
  spec.email       = 'gems@solutious.com'
  spec.homepage    = 'https://github.com/delano/tryouts'
  spec.license     = 'MIT'  # replace with actual license
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.8')

  spec.files = Dir['{lib,exe}/**/*', 'LICENSE.txt', 'README.md', 'VERSION.yml']  # Include the exe folder
  spec.bindir = 'exe'  # Specify that executables are in the exe folder
  spec.executables = Dir.chdir('exe'){ Dir['*'] }.select { |f| File.file?("exe/#{f}") }

  spec.add_dependency 'sysinfo', '~> 0.10'
end
