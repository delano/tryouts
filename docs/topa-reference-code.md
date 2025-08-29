# TOPA Reference Code - Implementation Snippets

This document provides the core Ruby code from Tryouts' agent-optimized formatter that should be translated for TOPA implementations in other languages.

## TokenBudget Class

**Location**: `lib/tryouts/cli/formatters/token_budget.rb`

### Core Class Structure
```ruby
class TokenBudget
  DEFAULT_LIMIT = 5000
  BUFFER_PERCENT = 0.05  # 5% buffer to avoid going over

  attr_reader :limit, :used, :remaining

  def initialize(limit = DEFAULT_LIMIT)
    @limit = limit
    @used = 0
    @buffer_size = (@limit * BUFFER_PERCENT).to_i
  end
end
```

### Token Estimation Method
```ruby
# Estimate tokens in text (rough approximation: 1 token ≈ 4 characters)
def estimate_tokens(text)
  return 0 if text.nil? || text.empty?
  (text.length / 4.0).ceil
end
```

### Budget Management Methods
```ruby
# Check if text would exceed budget
def would_exceed?(text)
  token_count = estimate_tokens(text)
  (@used + token_count) > (@limit - @buffer_size)
end

# Add text to budget if within limits
def consume(text)
  return false if would_exceed?(text)
  @used += estimate_tokens(text)
  true
end

# Force consume (for critical information that must be included)
def force_consume(text)
  @used += estimate_tokens(text)
  true
end

# Get remaining budget
def remaining
  [@limit - @used - @buffer_size, 0].max
end

# Check if we have budget remaining
def has_budget?
  remaining > 0
end
```

### Smart Truncation Methods
```ruby
# Try to fit text within remaining budget by truncating
def fit_text(text, preserve_suffix: nil)
  token_count = estimate_tokens(text)

  return text if token_count <= remaining
  return '' unless has_budget?

  # Calculate how many characters we can fit
  max_chars = remaining * 4

  if preserve_suffix
    suffix_chars = preserve_suffix.length
    return preserve_suffix if max_chars <= suffix_chars

    available_chars = max_chars - suffix_chars - 3  # 3 for "..."
    return "#{text[0, available_chars]}...#{preserve_suffix}"
  else
    return text[0, max_chars - 3] + '...' if max_chars > 3
    return ''
  end
end

# Smart truncate for different data types
def smart_truncate(value, max_tokens: nil)
  max_tokens ||= [remaining / 2, 50].min  # Use half remaining or 50, whichever is smaller
  max_chars = max_tokens * 4

  case value
  when String
    if value.length <= max_chars
      value
    else
      "#{value[0, max_chars - 3]}..."
    end
  when Array
    if estimate_tokens(value.inspect) <= max_tokens
      value.inspect
    else
      # Show first few elements
      truncated = []
      char_count = 2  # for "[]"

      value.each do |item|
        item_str = item.inspect
        if char_count + item_str.length + 2 <= max_chars - 10  # 10 chars for ", ..."
          truncated << item
          char_count += item_str.length + 2  # +2 for ", "
        else
          break
        end
      end

      "[#{truncated.map(&:inspect).join(', ')}, ...#{value.size - truncated.size} more]"
    end
  when Hash
    if estimate_tokens(value.inspect) <= max_tokens
      value.inspect
    else
      # Show first few key-value pairs
      truncated = {}
      char_count = 2  # for "{}"

      value.each do |key, val|
        pair_str = "#{key.inspect}=>#{val.inspect}"
        if char_count + pair_str.length + 2 <= max_chars - 10
          truncated[key] = val
          char_count += pair_str.length + 2
        else
          break
        end
      end

      "{#{truncated.map { |k, v| "#{k.inspect}=>#{v.inspect}" }.join(', ')}, ...#{value.size - truncated.size} more}"
    end
  else
    smart_truncate(value.to_s, max_tokens: max_tokens)
  end
end
```

### Budget Allocation Strategy
```ruby
# Distribution strategy for budget allocation
def allocate_budget
  {
    summary: (@limit * 0.20).to_i,      # 20% for file summaries
    failures: (@limit * 0.60).to_i,     # 60% for failure details
    context: (@limit * 0.15).to_i,      # 15% for additional context
    buffer: (@limit * 0.05).to_i        # 5% buffer
  }
end
```

## AgentFormatter Core Methods

**Location**: `lib/tryouts/cli/formatters/agent.rb`

### Initialization
```ruby
def initialize(options = {})
  @budget = TokenBudget.new(options[:agent_limit] || TokenBudget::DEFAULT_LIMIT)
  @focus_mode = options[:agent_focus] || :failures
  @collected_files = []
  @current_file_data = nil
  @total_stats = { files: 0, tests: 0, failures: 0, errors: 0, elapsed: 0 }
  @output_rendered = false

  # No colors in agent mode for cleaner parsing
  @use_colors = false
end
```

### File Data Collection
```ruby
def file_start(file_path, context_info: {})
  @current_file_data = {
    path: relative_path(file_path),
    tests: 0,
    failures: [],
    errors: [],
    passed: 0
  }
end

def test_result(result_packet)
  return unless @current_file_data

  if result_packet.failed? || result_packet.error?
    if @focus_mode == :summary
      # Just track counts for summary
      if result_packet.error?
        @current_file_data[:errors] << { basic: true }
      else
        @current_file_data[:failures] << { basic: true }
      end
    else
      # Build detailed failure data for other modes
      failure_data = build_failure_data(result_packet)

      if result_packet.error?
        @current_file_data[:errors] << failure_data
      else
        @current_file_data[:failures] << failure_data
      end
    end
  end
end
```

### Failure Data Builder
```ruby
def build_failure_data(result_packet)
  test_case = result_packet.test_case

  failure_data = {
    line: (test_case.first_expectation_line || test_case.line_range&.first || 0) + 1,
    test: test_case.description.to_s.empty? ? 'unnamed test' : test_case.description.to_s
  }

  case result_packet.status
  when :error
    error = result_packet.error
    failure_data[:error] = error ? "#{error.class.name}: #{error.message}" : 'unknown error'
  when :failed
    if result_packet.expected_results.any? && result_packet.actual_results.any?
      expected = @budget.smart_truncate(result_packet.first_expected, max_tokens: 25)
      actual = @budget.smart_truncate(result_packet.first_actual, max_tokens: 25)
      failure_data[:expected] = expected
      failure_data[:got] = actual
    else
      failure_data[:reason] = 'test failed'
    end
  end

  failure_data
end
```

### Focus Mode Rendering
```ruby
def render_agent_output
  case @focus_mode
  when :summary
    render_summary_only
  when :critical
    render_critical_only
  else
    render_full_structured
  end
end

def render_summary_only
  output = []

  # Count failures manually from collected file data
  failed_count = @collected_files.sum { |f| f[:failures].size }
  error_count = @collected_files.sum { |f| f[:errors].size }
  issues_count = failed_count + error_count
  passed_count = [@total_stats[:tests] - issues_count, 0].max

  if issues_count > 0
    status = "FAIL: #{issues_count}/#{@total_stats[:tests]} tests"
    details = []
    details << "#{failed_count} failed" if failed_count > 0
    details << "#{error_count} errors" if error_count > 0
    status += " (#{details.join(', ')}, #{passed_count} passed)"
  else
    status = "PASS: #{@total_stats[:tests]} tests passed"
  end

  status += " (#{format_time(@total_stats[:elapsed])})" if @total_stats[:elapsed]

  output << status

  # Show which files had failures
  files_with_issues = @collected_files.select { |f| f[:failures].any? || f[:errors].any? }
  if files_with_issues.any?
    output << ""
    output << "Files with issues:"
    files_with_issues.each do |file_data|
      issue_count = file_data[:failures].size + file_data[:errors].size
      output << "  #{file_data[:path]}: #{issue_count} issue#{'s' if issue_count != 1}"
    end
  end

  puts output.join("\n")
end
```

## Utility Functions

### Path Normalization
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

### Time Formatting
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

### File Section Renderer
```ruby
def render_file_section(file_data)
  lines = []

  # File header
  lines << "#{file_data[:path]}:"

  # For first-failure mode, only show first error or failure
  if @focus_mode == :first_failure || @focus_mode == :'first-failure'
    shown_count = 0

    # Show first error
    if file_data[:errors].any? && shown_count == 0
      error = file_data[:errors].first
      lines << "  L#{error[:line]}: #{error[:error]}"
      lines << "    Test: #{error[:test]}" if error[:test] != 'unnamed test'
      shown_count += 1
    end

    # Show first failure if no error was shown
    if file_data[:failures].any? && shown_count == 0
      failure = file_data[:failures].first
      line_parts = ["  L#{failure[:line]}:"]

      if failure[:expected] && failure[:got]
        line_parts << "expected #{failure[:expected]}, got #{failure[:got]}"
      elsif failure[:reason]
        line_parts << failure[:reason]
      end

      lines << line_parts.join(' ')
      lines << "    Test: #{failure[:test]}" if failure[:test] != 'unnamed test'
    end

    # Show truncation notice
    total_issues = file_data[:errors].size + file_data[:failures].size
    if total_issues > 1
      lines << "  ... (#{total_issues - 1} more failures not shown)"
    end
  else
    # Normal mode - show all errors and failures
    # Errors first (more critical)
    file_data[:errors].each do |error|
      next if error[:basic]  # Skip basic entries from summary mode
      lines << "  L#{error[:line]}: #{error[:error]}"
      lines << "    Test: #{error[:test]}" if error[:test] != 'unnamed test'
    end

    # Then failures
    file_data[:failures].each do |failure|
      next if failure[:basic]  # Skip basic entries from summary mode
      line_parts = ["  L#{failure[:line]}:"]

      if failure[:expected] && failure[:got]
        line_parts << "expected #{failure[:expected]}, got #{failure[:got]}"
      elsif failure[:reason]
        line_parts << failure[:reason]
      end

      lines << line_parts.join(' ')
      lines << "    Test: #{failure[:test]}" if failure[:test] != 'unnamed test'
    end
  end

  lines.join("\n")
end
```

## Data Structures

### Test Result Data
```ruby
# Main stats tracking
@total_stats = {
  files: 0,
  tests: 0,
  failures: 0,
  errors: 0,
  elapsed: 0
}

# Per-file data structure
@current_file_data = {
  path: relative_path(file_path),
  tests: 0,
  failures: [],
  errors: [],
  passed: 0
}

# Individual failure data
failure_data = {
  line: line_number,
  test: test_description,
  expected: truncated_expected_value,
  got: truncated_actual_value,
  error: error_message,  # for errors
  diff: optional_diff    # if budget allows
}
```

## Integration Points

### Focus Mode Constants
```ruby
FOCUS_MODES = %i[failures first-failure summary critical]
```

### Output Structure Template
```ruby
def render_full_structured
  output = []

  # Status line (always force_consume)
  status_line = "#{status}: #{issues_count}/#{@total_stats[:tests]} tests (#{@total_stats[:files]} files, #{format_time(@total_stats[:elapsed])})"
  output << status_line
  @budget.force_consume(status_line)

  # File sections (budget permitting)
  files_to_show.each do |file_data|
    break unless @budget.has_budget?

    file_section = render_file_section(file_data)
    if @budget.would_exceed?(file_section)
      truncated = @budget.fit_text(file_section, preserve_suffix: "\n  ... (truncated)")
      output << truncated if truncated.length > 20
      break
    else
      output << file_section
      @budget.consume(file_section)
    end
  end

  # Summary line
  summary = "Summary: #{passed_count} passed, #{@total_stats[:failures]} failed"
  summary += ", #{@total_stats[:errors]} errors" if @total_stats[:errors] > 0
  summary += " in #{@total_stats[:files]} files"

  output << ""
  output << summary

  puts output.join("\n")
end
```

## Language Adaptation Notes

### Python Implementation
- Use `len(text) // 4` for token estimation
- Replace `attr_reader` with properties
- Use `dataclasses` for structured data
- Handle `None` values in truncation

### JavaScript Implementation
- Use `Math.ceil(text.length / 4)` for tokens
- Replace Hash with Map or Object
- Handle `undefined` and `null` gracefully
- Use template literals for string formatting

### Go Implementation
- Use `len(text) / 4` with proper rounding
- Create structs for data structures
- Handle pointer/nil checks in truncation
- Use `fmt.Sprintf` for formatting

### Java Implementation
- Use `text.length() / 4` with `Math.ceil()`
- Create classes with proper encapsulation
- Handle `null` values consistently
- Use StringBuilder for efficient concatenation

## Testing Integration

### Token Estimation Validation
```ruby
# Test cases for token estimation accuracy
def test_token_estimation
  assert_equal 1, estimate_tokens("test")      # 4 chars
  assert_equal 3, estimate_tokens("hello world") # 11 chars
  assert_equal 0, estimate_tokens("")          # 0 chars
  assert_equal 0, estimate_tokens(nil)         # nil
end
```

### Focus Mode Validation
```ruby
# Verify focus modes produce expected output patterns
def test_focus_modes
  # Summary: only status and file list
  assert_match(/PASS: \d+ tests/, summary_output)
  refute_match(/L\d+:/, summary_output)

  # First-failure: exactly one failure per file
  first_failure_lines = first_failure_output.split("\n").select { |line| line.match(/L\d+:/) }
  assert_equal 1, first_failure_lines.count

  # Critical: only errors, no assertion failures
  assert_match(/CRITICAL:/, critical_output)
  assert_match(/Error:/, critical_output)
end
```

This reference implementation provides all the core logic needed to recreate the TOPA format in any programming language while maintaining the same token efficiency and structural characteristics.
