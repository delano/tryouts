# tryouts.gemspec

require_relative 'lib/tryouts/version'

Gem::Specification.new do |spec|
  spec.name                  = 'tryouts'
  spec.version               = Tryouts::VERSION
  spec.summary               = 'Ruby tests that read like documentation.'
  spec.description           = 'A simple test framework for Ruby code where the test descriptions and expectations are written as comments.'
  spec.author                = 'Delano Mandelbaum'
  spec.email                 = 'gems@solutious.com'
  spec.homepage              = 'https://github.com/delano/tryouts'
  spec.license               = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2')

  spec.files       = Dir['{lib,exe}/**/*', 'LICENSE.txt', 'README.md'] # Include the exe folder
  spec.bindir      = 'exe'
  spec.executables = Dir['exe/*'].select { |f| File.file?(f) }.map { |f| File.basename(f) }

  spec.add_dependency 'irb'
  spec.add_dependency 'prism', '~> 1.0'

  # TTY ecosystem for live terminal formatting
  spec.add_dependency 'minitest', '~> 5.0'
  spec.add_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'pastel', '~> 0.8'
  spec.add_dependency 'tty-cursor', '~> 0.7'
  spec.add_dependency 'tty-screen', '~> 0.8'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
