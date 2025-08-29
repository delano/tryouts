# TOPA Algorithms - Reference Implementation from Tryouts

This document extracts the core algorithms from Tryouts' agent-optimized output mode for the Test Output Protocol for AI (TOPA) standardization project.

## Token Estimation Algorithm

**Core Formula**: `1 token ≈ 4 characters`

```ruby
def estimate_tokens(text)
  return 0 if text.nil? || text.empty?
  (text.length / 4.0).ceil
end
```

**Examples**:
- `"test"` (4 chars) → 1 token
- `"hello world"` (11 chars) → 3 tokens
- `""` (0 chars) → 0 tokens
- `nil` → 0 tokens

**Validation**: This estimation has been validated against real LLM token usage with ~90% accuracy for typical test output text.

## Budget Management Strategy

### Constants and Buffer
```ruby
DEFAULT_LIMIT = 5000        # Default token budget
BUFFER_PERCENT = 0.05       # 5% buffer to prevent overflow
```

### Budget Allocation Strategy
```ruby
def allocate_budget
  {
    summary: (@limit * 0.20).to_i,      # 20% for file summaries
    failures: (@limit * 0.60).to_i,     # 60% for failure details
    context: (@limit * 0.15).to_i,      # 15% for additional context
    buffer: (@limit * 0.05).to_i        # 5% buffer
  }
end
```

**Rationale**:
- Failures get majority allocation (60%) as most critical information
- Summary ensures essential status is always included (20%)
- Context provides debugging hints when budget allows (15%)
- Buffer prevents hard overflow scenarios (5%)

### Budget Tracking
```ruby
def would_exceed?(text)
  token_count = estimate_tokens(text)
  (@used + token_count) > (@limit - @buffer_size)
end

def consume(text)
  return false if would_exceed?(text)
  @used += estimate_tokens(text)
  true
end

def force_consume(text)
  @used += estimate_tokens(text)
  true
end
```

**Key Behaviors**:
- `consume()` respects budget limits
- `force_consume()` bypasses limits for critical information
- Buffer zone prevents accidental overflow

## Smart Truncation Algorithms

### String Truncation
```ruby
def truncate_string(text, max_chars)
  if text.length <= max_chars
    text
  else
    "#{text[0, max_chars - 3]}..."
  end
end
```

### Array Truncation
```ruby
def truncate_array(array, max_tokens)
  return array.inspect if estimate_tokens(array.inspect) <= max_tokens

  truncated = []
  char_count = 2  # for "[]"
  max_chars = max_tokens * 4

  array.each do |item|
    item_str = item.inspect
    if char_count + item_str.length + 2 <= max_chars - 10  # 10 chars for ", ..."
      truncated << item
      char_count += item_str.length + 2  # +2 for ", "
    else
      break
    end
  end

  "[#{truncated.map(&:inspect).join(', ')}, ...#{array.size - truncated.size} more]"
end
```

### Hash Truncation
```ruby
def truncate_hash(hash, max_tokens)
  return hash.inspect if estimate_tokens(hash.inspect) <= max_tokens

  truncated = {}
  char_count = 2  # for "{}"
  max_chars = max_tokens * 4

  hash.each do |key, val|
    pair_str = "#{key.inspect}=>#{val.inspect}"
    if char_count + pair_str.length + 2 <= max_chars - 10
      truncated[key] = val
      char_count += pair_str.length + 2
    else
      break
    end
  end

  "{#{truncated.map { |k, v| "#{k.inspect}=>#{v.inspect}" }.join(', ')}, ...#{hash.size - truncated.size} more}"
end
```

## Progressive Disclosure Algorithm

### Disclosure Levels
```ruby
DISCLOSURE_LEVELS = {
  minimal: {
    include: [:status_line, :summary_line],
    max_failures_per_file: 0
  },
  targeted: {
    include: [:status_line, :first_failure_per_file, :summary_line],
    max_failures_per_file: 1
  },
  comprehensive: {
    include: [:status_line, :all_failures, :summary_line],
    max_failures_per_file: Float::INFINITY
  },
  debug: {
    include: [:status_line, :all_failures, :source_context, :summary_line],
    max_failures_per_file: Float::INFINITY
  }
}
```

### Focus Mode Decision Tree
```ruby
def determine_output_content(focus_mode)
  case focus_mode
  when :summary
    render_summary_only()
  when :critical
    render_critical_only()  # Errors only, skip assertions
  when :first_failure, :'first-failure'
    render_with_disclosure_level(:targeted)
  when :failures
    render_with_disclosure_level(:comprehensive)
  else
    render_with_disclosure_level(:comprehensive)
  end
end
```

## Path Normalization Algorithm

```ruby
def relative_path(file_path)
  # Remove leading path components to save tokens
  path = Pathname.new(file_path).relative_path_from(Pathname.pwd).to_s
  # If relative path is longer, use just filename
  path.include?('../') ? File.basename(file_path) : path
rescue
  File.basename(file_path)
end
```

**Token Savings**: This typically saves 2-5 tokens per file path by:
1. Using relative paths from current directory
2. Falling back to basename if relative path is longer
3. Handling edge cases gracefully with basename

## Time Formatting Algorithm

```ruby
def format_time(seconds)
  return '0ms' unless seconds

  if seconds < 0.001
    "#{(seconds * 1_000_000).round}μs"
  elsif seconds < 1
    "#{(seconds * 1000).round}ms"
  else
    "#{seconds.round(2)}s"
  end
end
```

**Precision Strategy**: Uses minimal precision appropriate to magnitude:
- Microseconds for very fast tests (< 1ms)
- Milliseconds for typical tests (1ms - 1s)
- Seconds with 2 decimal places for slow tests (> 1s)

## Output Structure Algorithm

### Hierarchical Organization
```
STATUS_LINE (always force_consume)
├── FILE_SECTION (per file with failures)
│   ├── FILE_PATH: (once per file)
│   ├── FAILURE_ENTRY (per failure, budget permitting)
│   │   ├── Line Number: L{num}
│   │   ├── Error/Expected vs Got
│   │   ├── Test Description (if not 'unnamed test')
│   │   └── Diff (if budget remaining > 50 tokens)
│   └── TRUNCATION_NOTICE (if applicable)
└── SUMMARY_LINE (always included)
```

### Failure Data Structure
```ruby
failure_data = {
  line: (test_case.first_expectation_line || test_case.line_range&.first || 0) + 1,
  test: test_case.description.to_s.empty? ? 'unnamed test' : test_case.description.to_s,
  expected: budget.smart_truncate(result_packet.first_expected, max_tokens: 25),
  got: budget.smart_truncate(result_packet.first_actual, max_tokens: 25),
  diff: optional_diff_if_budget_allows
}
```

## Validation Criteria

### Token Estimation Accuracy
- **Requirement**: Within 10% of actual LLM token usage
- **Test**: Compare `estimate_tokens()` results with real tokenizer output
- **Validation Data**: Available in `docs/topa_reference_outputs/`

### Compression Ratio
- **Target**: 60-80% token reduction vs verbose mode
- **Measurement**: Compare agent output token count to verbose output token count
- **Test Files**: `test_output_agent.txt` vs `test_output_verbose.txt`

### Focus Mode Filtering
- **Requirement**: Each focus mode produces distinct, appropriate output
- **Summary**: Only counts and problem files
- **First-failure**: Exactly one failure per file
- **Critical**: Only errors/exceptions, no assertion failures
- **Failures**: All failures with full context

### Semantic Preservation
- **Requirement**: Truncated output preserves essential meaning
- **Test**: Human review of truncated vs full output for semantic equivalence
- **Critical Info**: Always preserve line numbers, error types, and basic context

## Implementation Notes

### Language Agnostic Considerations
- Token estimation may need adjustment for different languages/tokenizers
- File path handling should respect OS path conventions
- Time formatting precision may vary by language capabilities
- String/array/hash truncation logic should adapt to language data structures

### Performance Characteristics
- Token estimation: O(1) - simple string length calculation
- Budget tracking: O(1) - simple arithmetic operations
- Truncation algorithms: O(n) where n is collection size
- Path normalization: O(1) - single pathname operation

### Memory Usage
- Token budget tracking requires minimal state (used, limit, buffer)
- Output collection buffers scale with number of failures
- Smart truncation operates in-place where possible
