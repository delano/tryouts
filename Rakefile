require "bundler/gem_tasks"
require "rake/extensiontask"

Rake::ExtensionTask.new("tree_sitter_ruby") do |ext|
  ext.lib_dir = "lib/tree_sitter"
  ext.ext_dir = "ext/tree-sitter-ruby"
  ext.name = "ruby"
end


#require 'rake/clean'
#
#CLEAN.include('ext/**/*.o', 'ext/**/*.so')
#CLOBBER.include('ext/**/Makefile')
#
#desc 'Compile the extension'
#task :compile do
#  Dir.chdir('ext') do
#    ruby 'extconf.rb'
#    sh 'make'
#    sh 'make install'
#  end
#end

task :default => :compile
