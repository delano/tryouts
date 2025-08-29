# Comprehensive tests for TokenBudget class
# Tests token estimation, budget management, and smart truncation

require_relative '../../lib/tryouts/cli/formatters/token_budget'

## Test default initialization
@default_budget = Tryouts::CLI::TokenBudget.new
@default_budget.limit
#=> 5000

@default_budget.used
#=> 0

## Test custom initialization
@@custom_budget = Tryouts::CLI::TokenBudget.new(1000)
@@custom_budget.limit
#=> 1000

## Test buffer calculation (5% buffer)
expected_buffer = (1000 * 0.05).to_i
remaining_with_buffer = @@custom_budget.remaining
remaining_with_buffer
#=> 950  # 1000 - 50 (5% buffer)

# Test token estimation accuracy
text_4_chars = "test"
@@custom_budget.estimate_tokens(text_4_chars)
#=> 1

text_8_chars = "testtest"
@custom_budget.estimate_tokens(text_8_chars)
#=> 2

text_empty = ""
@custom_budget.estimate_tokens(text_empty)
#=> 0

text_nil = nil
@custom_budget.estimate_tokens(text_nil)
#=> 0

# Test consumption tracking
small_text = "hello"  # 5 chars = ~2 tokens
@custom_budget.consume(small_text)
#=> true

@custom_budget.used
#=> 2

@custom_budget.remaining
#=> 948

# Test would_exceed calculation
very_large_text = "x" * 4000  # 4000 chars = 1000 tokens, should exceed with buffer
@custom_budget.would_exceed?(very_large_text)
#=> true

medium_text = "x" * 200  # 200 chars = 50 tokens, should fit
@custom_budget.would_exceed?(medium_text)
#=> false

# Test force_consume (ignores limits)
large_text = "x" * 2000  # Would normally exceed
result = @custom_budget.force_consume(large_text)
result
#=> true

# Usage should increase even though it exceeded
@custom_budget.used > 400  # Should be much higher now
#=> true

# Test utilization calculation
utilization = @custom_budget.utilization
utilization.class
#=> Float

utilization > 0
#=> true

# Test fit_text functionality
new_budget = Tryouts::CLI::TokenBudget.new(100)
long_text = "This is a very long text that should be truncated to fit within the budget limits"

fitted = new_budget.fit_text(long_text)
fitted.length < long_text.length
#=> true

fitted.end_with?("...")
#=> true

# Test fit_text with preserve_suffix
fitted_with_suffix = new_budget.fit_text(long_text, preserve_suffix: " [truncated]")
fitted_with_suffix.end_with?(" [truncated]")
#=> true

# Test smart_truncate for different data types
truncate_budget = Tryouts::CLI::TokenBudget.new(500)

# String truncation
long_string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10
truncated_string = truncate_budget.smart_truncate(long_string, max_tokens: 20)
truncated_string.length < long_string.length
#=> true

# Array truncation
large_array = (1..100).to_a
truncated_array = truncate_budget.smart_truncate(large_array, max_tokens: 30)
truncated_array.include?("more")
#=> true

truncated_array.include?("...")
#=> true

# Hash truncation
large_hash = Hash[(1..50).map { |i| [i, "value_#{i}"] }]
truncated_hash = truncate_budget.smart_truncate(large_hash, max_tokens: 25)
truncated_hash.include?("more")
#=> true

# Test boundary conditions
edge_budget = Tryouts::CLI::TokenBudget.new(10)

# Very small budget
tiny_text = "hi"
edge_budget.consume(tiny_text)
#=> true

# Exact budget usage
edge_budget.reset
edge_budget.used
#=> 0

# Test has_budget functionality
edge_budget.has_budget?
#=> true

# Consume most budget
edge_budget.consume("x" * 30)  # Should consume most of the 10 token budget
remaining = edge_budget.has_budget?
remaining.class
#=> TrueClass

# Test allocation strategy
allocation_budget = Tryouts::CLI::TokenBudget.new(2000)
allocation = allocation_budget.allocate_budget

allocation[:summary]
#=> 400    # 20% of 2000

allocation[:failures]
#=> 1200   # 60% of 2000

allocation[:context]
#=> 300    # 15% of 2000

allocation[:buffer]
#=> 100    # 5% of 2000

# Test reset functionality
reset_budget = Tryouts::CLI::TokenBudget.new(100)
reset_budget.consume("test text")
reset_budget.used > 0
#=> true

reset_budget.reset
reset_budget.used
#=> 0

reset_budget.remaining > 90  # Back to initial state minus buffer
#=> true

# Test to_s representation
string_budget = Tryouts::CLI::TokenBudget.new(200)
string_budget.consume("test")
string_rep = string_budget.to_s
string_rep.include?("TokenBudget")
#=> true

string_rep.include?("200")
#=> true

puts "Token budget tests completed successfully"
