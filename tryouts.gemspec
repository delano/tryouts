Gem::Specification.new do |spec|
  spec.name        = 'tryouts'
  spec.version     = '3.0.0-alpha.1'
  spec.summary     = 'Ruby tests that read like documentation.'
  spec.description = 'A simple test framework for Ruby code that uses introspection to allow defining checks in comments.'
  spec.author      = 'Delano Mandelbaum'
  spec.email       = 'gems@solutious.com'
  spec.homepage    = 'https://github.com/delano/tryouts'
  spec.license     = 'MIT' # replace with actual license

  spec.files = Dir['{lib,exe}/**/*', 'LICENSE.txt', 'README.md'] # Include the exe folder
  spec.bindir = 'exe' # Specify that executables are in the exe folder
  spec.executables = Dir.chdir('exe') { Dir['*'] }.select { |f| File.file?("exe/#{f}") }

  spec.extensions = ['ext/extconf.rb']

  spec.required_ruby_version = '>= 2.7.8'

  spec.add_dependency 'ffi'
  spec.add_runtime_dependency 'rake-compiler'
  spec.add_runtime_dependency 'ruby_tree_sitter', '~> 1.6'
  spec.add_runtime_dependency 'stringio', '~> 3.1.2'
  spec.add_runtime_dependency 'sysinfo', '~> 0.10'
  spec.add_runtime_dependency 'tree_stand', '~> 0.2.0'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
