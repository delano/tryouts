# Gemfile

source 'https://rubygems.org'

gemspec

gem 'prism', '~> 1.0'

# TTY ecosystem for live terminal formatting
gem 'tty-cursor', '~> 0.7'
gem 'tty-screen', '~> 0.8'
gem 'pastel', '~> 0.8'

group :development do
  gem 'byebug', require: false
  # Enable for Debug Adapter Protocol. Not included with the development group
  # group because it lags on byebug version.
  # gem 'byebug-dap', require: false
  gem 'pry', require: false
  gem 'pry-byebug', require: false
  gem 'rack-proxy', require: false
  gem 'rubocop', '~>1.79', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-thread_safety', require: false
  gem 'stackprof', require: false
  gem 'syntax_tree', require: false
end

group :test do
  gem 'rack-test', require: false
  gem 'rspec', git: 'https://github.com/rspec/rspec'
  gem 'simplecov', require: false
  %w[rspec-core rspec-expectations rspec-mocks rspec-support].each do |lib|
    gem lib, git: 'https://github.com/rspec/rspec', glob: "#{lib}/#{lib}.gemspec"
  end
end
