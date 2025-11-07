# try/formatters/agent_formatter_try.rb
#
# frozen_string_literal: true

# Comprehensive tests for AgentFormatter functionality
# Tests agent-optimized output modes for LLM context management

require_relative '../../lib/tryouts/cli/formatters/agent'
require_relative '../../lib/tryouts/cli/formatters/token_budget'

## Test TokenBudget initialization and basic functionality
@budget = Tryouts::CLI::TokenBudget.new(100)
@budget.limit
#=> 100

## Test TokenBudget starts with zero usage
@budget.used
#=> 0

## Test TokenBudget remaining accounts for buffer
@budget.remaining > 90  # Account for 5% buffer
#=> true

## Test token estimation (1 token ≈ 4 characters)
@budget.estimate_tokens("test")
#=> 1

## Test token estimation for longer text
@budget.estimate_tokens("hello world")
#=> 3

## Test budget consumption
@budget.consume("test")
#=> true

## Test budget usage tracking
@budget.used
#=> 1

## Test remaining budget after consumption
@budget.remaining < 95
#=> true

## Test would_exceed functionality
@budget.would_exceed?("a" * 400)  # Should exceed 100 token limit with buffer
#=> true

## Test would_exceed with short text
short_text = "short"
@budget.would_exceed?(short_text)
#=> false

## Test smart truncation for different data types
@budget_large = Tryouts::CLI::TokenBudget.new(1000)

# String truncation
long_string = "a" * 200
@result = @budget_large.smart_truncate(long_string, max_tokens: 10)
@result.length < long_string.length
#=> true

## Test string truncation adds ellipsis
@budget_large = Tryouts::CLI::TokenBudget.new(1000)
long_string = "a" * 200
@result = @budget_large.smart_truncate(long_string, max_tokens: 10)
@result.end_with?("...")
#=> true

## Test array truncation
large_array = (1..50).to_a
truncated = @budget_large.smart_truncate(large_array, max_tokens: 20)
truncated.include?("more")
#=> true

## Test budget allocation strategy
allocation = @budget_large.allocate_budget
allocation[:summary] + allocation[:failures] + allocation[:context] + allocation[:buffer]
#=> 1000

## Test AgentFormatter initialization
@formatter = Tryouts::CLI::AgentFormatter.new
@formatter.class.name
#=> "Tryouts::CLI::AgentFormatter"

## Test AgentFormatter with options
opts_formatter = Tryouts::CLI::AgentFormatter.new({
  agent_limit: 2000,
  agent_focus: :summary
})
# Should initialize without errors
opts_formatter.class
#=> Tryouts::CLI::AgentFormatter

## Test relative path functionality (private method)
@formatter.send(:relative_path, "/tmp/test.rb").end_with?("test.rb")
#=> true

## Test time formatting (private method)
@formatter.send(:format_time, 0.0001)  # 100 microseconds
#=> "100μs"

## Test time formatting for milliseconds
@formatter.send(:format_time, 0.05)    # 50 milliseconds
#=> "50ms"

## Test time formatting for seconds
@formatter.send(:format_time, 1.5)     # 1.5 seconds
#=> "1.5s"

## Test that agent mode has no colors
@formatter.instance_variable_get(:@use_colors)
#=> false

puts "Agent formatter tests completed successfully"
