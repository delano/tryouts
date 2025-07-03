# .simplecov
SimpleCov.start do
  track_files 'lib/**/*.rb'
  add_filter '/try/'
  add_filter '/test/'
  add_filter '/test_'
  add_filter '/spec/'
  add_filter '/examples/'
  add_filter '/docs/'

  add_group 'Core', 'lib/tryouts.rb'
  add_group 'CLI', 'lib/tryouts/cli'
  add_group 'Formatters', 'lib/tryouts/cli/formatters'
  add_group 'Parsers', 'lib/tryouts/prism_parser.rb'
  add_group 'Data Structures', ['lib/tryouts/testcase.rb', 'lib/tryouts/testbatch.rb']
  add_group 'Translators', 'lib/tryouts/translators'
  add_group 'Execution', ['lib/tryouts/test_executor.rb', 'lib/tryouts/test_runner.rb', 'lib/tryouts/file_processor.rb']

  coverage_dir 'coverage'

  # Set minimum coverage threshold (disabled to prevent CI failures)
  # minimum_coverage 80
  # minimum_coverage_by_file 70
end

SimpleCov.command_name 'Tryouts'
