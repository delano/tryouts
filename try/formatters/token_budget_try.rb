# try/formatters/token_budget_try.rb
#
# frozen_string_literal: true

# Comprehensive tests for TokenBudget class
# Tests token estimation, budget management, and smart truncation

require_relative '../../lib/tryouts/cli/formatters/token_budget'

## Test default initialization
@default_budget = Tryouts::CLI::TokenBudget.new
@default_budget.limit
#=> 5000

## Test default budget starts with zero usage
@default_budget.used
#=> 0

## Test custom initialization
@custom_budget = Tryouts::CLI::TokenBudget.new(1000)
@custom_budget.limit
#=> 1000

## Test buffer calculation (5% buffer)
expected_buffer = (1000 * 0.05).to_i
remaining_with_buffer = @custom_budget.remaining
remaining_with_buffer
#=> 950

## Test token estimation for 4 character text
text_4_chars = "test"
@custom_budget.estimate_tokens(text_4_chars)
#=> 1

## Test token estimation for 8 character text
text_8_chars = "testtest"
@custom_budget.estimate_tokens(text_8_chars)
#=> 2

## Test token estimation for empty string
text_empty = ""
@custom_budget.estimate_tokens(text_empty)
#=> 0

## Test token estimation for nil
text_nil = nil
@custom_budget.estimate_tokens(text_nil)
#=> 0

## Test consumption tracking
small_text = "hello"  # 5 chars = ~2 tokens
@custom_budget.consume(small_text)
#=> true

## Test used tokens after consumption
@custom_budget.used
#=> 2

## Test remaining tokens after consumption
@custom_budget.remaining
#=> 948

## Test would_exceed with very large text
very_large_text = "x" * 4000  # 4000 chars = 1000 tokens, should exceed with buffer
@custom_budget.would_exceed?(very_large_text)
#=> true

## Test would_exceed with medium text
medium_text = "x" * 200  # 200 chars = 50 tokens, should fit
@custom_budget.would_exceed?(medium_text)
#=> false

## Test force_consume ignores limits
large_text = "x" * 2000  # Would normally exceed
result = @custom_budget.force_consume(large_text)
result
#=> true

## Test usage increases after force_consume
@custom_budget.used > 400  # Should be much higher now
#=> true

## Test utilization calculation returns Float
utilization = @custom_budget.utilization
utilization.class
#=> Float

## Test utilization is positive after consumption
utilization = @custom_budget.utilization
utilization > 0
#=> true

## Test fit_text truncates long text
new_budget = Tryouts::CLI::TokenBudget.new(10)  # Much smaller budget
long_text = "This is a very long text that should be truncated to fit within the budget limits"
fitted = new_budget.fit_text(long_text)
fitted.length < long_text.length
#=> true

## Test fit_text adds ellipsis
new_budget = Tryouts::CLI::TokenBudget.new(10)  # Much smaller budget
long_text = "This is a very long text that should be truncated to fit within the budget limits"
fitted = new_budget.fit_text(long_text)
fitted.end_with?("...")
#=> true

## Test fit_text with preserve_suffix
new_budget = Tryouts::CLI::TokenBudget.new(10)  # Much smaller budget
long_text = "This is a very long text that should be truncated to fit within the budget limits"
fitted_with_suffix = new_budget.fit_text(long_text, preserve_suffix: " [truncated]")
fitted_with_suffix.end_with?(" [truncated]")
#=> true

## Test smart_truncate for string
truncate_budget = Tryouts::CLI::TokenBudget.new(500)
long_string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10
truncated_string = truncate_budget.smart_truncate(long_string, max_tokens: 20)
truncated_string.length < long_string.length
#=> true

## Test smart_truncate for array
truncate_budget = Tryouts::CLI::TokenBudget.new(500)
large_array = (1..100).to_a
truncated_array = truncate_budget.smart_truncate(large_array, max_tokens: 30)
truncated_array.include?("more")
#=> true

## Test array truncation includes ellipsis
truncate_budget = Tryouts::CLI::TokenBudget.new(500)
large_array = (1..100).to_a
truncated_array = truncate_budget.smart_truncate(large_array, max_tokens: 30)
truncated_array.include?("...")
#=> true

## Test smart_truncate for hash
truncate_budget = Tryouts::CLI::TokenBudget.new(500)
large_hash = Hash[(1..50).map { |i| [i, "value_#{i}"] }]
truncated_hash = truncate_budget.smart_truncate(large_hash, max_tokens: 25)
truncated_hash.include?("more")
#=> true

## Test consumption with small budget
edge_budget = Tryouts::CLI::TokenBudget.new(10)
tiny_text = "hi"
edge_budget.consume(tiny_text)
#=> true

## Test budget reset functionality
edge_budget = Tryouts::CLI::TokenBudget.new(10)
edge_budget.consume("test")
edge_budget.reset
edge_budget.used
#=> 0

## Test has_budget returns true for fresh budget
edge_budget = Tryouts::CLI::TokenBudget.new(10)
edge_budget.has_budget?
#=> true

## Test budget consumption affects has_budget
edge_budget = Tryouts::CLI::TokenBudget.new(10)
edge_budget.consume("x" * 30)  # Should consume most of the 10 token budget
remaining = edge_budget.has_budget?
remaining.class
#=> TrueClass

## Test budget allocation strategy summary
allocation_budget = Tryouts::CLI::TokenBudget.new(2000)
allocation = allocation_budget.allocate_budget
allocation[:summary]
#=> 400

## Test budget allocation strategy failures
allocation_budget = Tryouts::CLI::TokenBudget.new(2000)
allocation = allocation_budget.allocate_budget
allocation[:failures]
#=> 1200

## Test budget allocation strategy context
allocation_budget = Tryouts::CLI::TokenBudget.new(2000)
allocation = allocation_budget.allocate_budget
allocation[:context]
#=> 300

## Test budget allocation strategy buffer
allocation_budget = Tryouts::CLI::TokenBudget.new(2000)
allocation = allocation_budget.allocate_budget
allocation[:buffer]
#=> 100

## Test reset returns budget to initial state
reset_budget = Tryouts::CLI::TokenBudget.new(100)
reset_budget.consume("test text")
reset_budget.reset
reset_budget.used
#=> 0

## Test remaining budget after reset
reset_budget = Tryouts::CLI::TokenBudget.new(100)
reset_budget.consume("test text")
reset_budget.reset
reset_budget.remaining > 90  # Back to initial state minus buffer
#=> true

## Test to_s includes class name
string_budget = Tryouts::CLI::TokenBudget.new(200)
string_budget.consume("test")
string_rep = string_budget.to_s
string_rep.include?("TokenBudget")
#=> true

## Test to_s includes limit
string_budget = Tryouts::CLI::TokenBudget.new(200)
string_budget.consume("test")
string_rep = string_budget.to_s
string_rep.include?("200")
#=> true

puts "Token budget tests completed successfully"
