#!/usr/bin/env ruby
# Parser comparison testing script
# Compares outputs of LegacyParser vs EnhancedParser

require_relative '../../lib/tryouts/parsers/legacy_parser'
require_relative '../../lib/tryouts/parsers/enhanced_parser'

class ParserComparison
  def initialize
    @results = {
      total_files: 0,
      identical_outputs: 0,
      different_outputs: 0,
      parser_errors: 0,
      differences: []
    }
  end

  def compare_all_test_files
    puts "=== Parser Comparison Testing ==="
    puts "Comparing LegacyParser vs EnhancedParser outputs\n\n"

    test_files = find_test_files
    puts "Found #{test_files.length} test files to compare\n"

    test_files.each do |file_path|
      compare_file(file_path)
    end

    print_summary
  end

  def compare_file(file_path)
    @results[:total_files] += 1

    print "Testing #{File.basename(file_path)}... "

    begin
      # Parse with both parsers
      prism_result = Tryouts::LegacyParser.new(file_path).parse
      enhanced_result = Tryouts::EnhancedParser.new(file_path).parse

      # Compare results
      differences = find_differences(prism_result, enhanced_result, file_path)

      if differences.empty?
        @results[:identical_outputs] += 1
        puts "✅ IDENTICAL"
      else
        @results[:different_outputs] += 1
        puts "❌ DIFFERENT"
        @results[:differences] << { file: file_path, differences: differences }

        # Show first few differences immediately for debugging
        differences.first(3).each do |diff|
          puts "  - #{diff}"
        end
      end

    rescue => e
      @results[:parser_errors] += 1
      puts "💥 ERROR: #{e.message}"
      @results[:differences] << {
        file: file_path,
        differences: ["Parser error: #{e.message}"]
      }
    end
  end

  private

  def find_test_files
    # Find all tryout test files
    patterns = [
      'try/**/*_try.rb',
      'try/**/test_*.rb'
    ]

    files = []
    patterns.each do |pattern|
      files.concat(Dir.glob(pattern))
    end

    files.uniq.sort
  end

  def find_differences(prism_result, enhanced_result, file_path)
    differences = []

    # Compare basic structure
    if prism_result.test_cases.length != enhanced_result.test_cases.length
      differences << "Test case count: #{prism_result.test_cases.length} vs #{enhanced_result.test_cases.length}"
    end

    # Compare setup
    if normalize_code(prism_result.setup.code) != normalize_code(enhanced_result.setup.code)
      differences << "Setup code differs"
    end

    # Compare teardown
    if normalize_code(prism_result.teardown.code) != normalize_code(enhanced_result.teardown.code)
      differences << "Teardown code differs"
    end

    # Compare test cases one by one
    min_tests = [prism_result.test_cases.length, enhanced_result.test_cases.length].min
    min_tests.times do |i|
      prism_test = prism_result.test_cases[i]
      enhanced_test = enhanced_result.test_cases[i]

      if prism_test.description != enhanced_test.description
        differences << "Test #{i+1} description: '#{prism_test.description}' vs '#{enhanced_test.description}'"
      end

      if normalize_code(prism_test.code) != normalize_code(enhanced_test.code)
        differences << "Test #{i+1} code differs"
      end

      if prism_test.expectations.length != enhanced_test.expectations.length
        differences << "Test #{i+1} expectation count: #{prism_test.expectations.length} vs #{enhanced_test.expectations.length}"
      end

      # Compare expectations
      min_expectations = [prism_test.expectations.length, enhanced_test.expectations.length].min
      min_expectations.times do |j|
        prism_exp = prism_test.expectations[j]
        enhanced_exp = enhanced_test.expectations[j]

        if prism_exp.content != enhanced_exp.content
          differences << "Test #{i+1} expectation #{j+1} content: '#{prism_exp.content}' vs '#{enhanced_exp.content}'"
        end

        if prism_exp.type != enhanced_exp.type
          differences << "Test #{i+1} expectation #{j+1} type: #{prism_exp.type} vs #{enhanced_exp.type}"
        end
      end
    end

    differences
  end

  def normalize_code(code)
    # Normalize whitespace and empty lines for comparison
    code.to_s.lines.map(&:strip).reject(&:empty?).join("\n")
  end

  def print_summary
    puts "\n" + "="*60
    puts "PARSER COMPARISON SUMMARY"
    puts "="*60
    puts "Total files tested: #{@results[:total_files]}"
    puts "Identical outputs:  #{@results[:identical_outputs]} (#{percentage(@results[:identical_outputs], @results[:total_files])}%)"
    puts "Different outputs:  #{@results[:different_outputs]} (#{percentage(@results[:different_outputs], @results[:total_files])}%)"
    puts "Parser errors:      #{@results[:parser_errors]} (#{percentage(@results[:parser_errors], @results[:total_files])}%)"

    if @results[:different_outputs] > 0
      puts "\n" + "-"*40
      puts "DETAILED DIFFERENCES:"
      puts "-"*40

      @results[:differences].each do |diff_info|
        puts "\n📄 #{diff_info[:file]}:"
        diff_info[:differences].each do |diff|
          puts "   • #{diff}"
        end
      end
    end

    puts "\n" + "="*60

    if @results[:parser_errors] > 0
      puts "❗ Parser errors encountered on #{@results[:parser_errors]} files"
      exit 2
    elsif @results[:identical_outputs] == @results[:total_files]
      puts "🎉 SUCCESS: All parsers produce identical results!"
      exit 0
    else
      puts "⚠️  WARNING: #{@results[:different_outputs]} files have different outputs"
      puts "   This may indicate issues with the EnhancedParser implementation"
      exit 1
    end
  end

  def percentage(count, total)
    return 0 if total == 0
    ((count.to_f / total) * 100).round(1)
  end
end

# Run comparison if called directly
if __FILE__ == $0
  ParserComparison.new.compare_all_test_files
end
