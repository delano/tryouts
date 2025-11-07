# TOPA Output Examples - Reference Formats

This document provides annotated examples of the Test Output Protocol for AI (TOPA) format based on Tryouts' agent-optimized output mode.

## Format Overview

TOPA uses a hierarchical, token-efficient structure:
```
STATUS_LINE
[FILE_SECTIONS]
SUMMARY_LINE
```

All examples below are actual outputs from Tryouts v3.7.1 agent mode.

## Example 1: Passing Tests (Agent Mode)

**Command**: `try --agent try/formatters/agent_formatter_try.rb`

**Output**:
```
PASS: 21 tests (1 files, 0μs)

Summary: 21 passed, 0 failed in 1 files
```

**Token Count**: ~15 tokens (60 characters)

**Analysis**:
- Minimal output for passing tests
- Status line includes test count, file count, timing
- Summary line confirms breakdown
- No file sections needed (no failures to report)

## Example 2: Summary Focus Mode

**Command**: `try --agent --agent-focus summary try/formatters/agent_formatter_try.rb`

**Output**:
```
PASS: 21 tests passed (0μs)
```

**Token Count**: ~6 tokens (25 characters)

**Analysis**:
- Most compact format possible
- Only essential status information
- 83% token reduction vs standard agent mode
- Perfect for quick status checks

## Example 3: Mixed Results (Standard Agent Mode)

**Command**: `try --agent try/formatters/`

**Output**:
```
FAIL: 10/104 tests (6 files, 0μs)

try/formatters/token_budget_try.rb:
  L32: NoMethodError: undefined method 'estimate_tokens' for nil
  L36: NoMethodError: undefined method 'estimate_tokens' for nil
  L40: NoMethodError: undefined method 'estimate_tokens' for nil
  L45: NoMethodError: undefined method 'consume' for nil
  L48: NoMethodError: undefined method 'used' for nil
  L51: NoMethodError: undefined method 'remaining' for nil
  L56: NoMethodError: undefined method 'would_exceed?' for nil
  L60: NoMethodError: undefined method 'would_exceed?' for nil
  L66: NoMethodError: undefined method 'force_consume' for nil
  L70: NoMethodError: undefined method 'used' for nil

Summary: 94 passed, 0 failed, 10 errors in 6 files
```

**Token Count**: ~185 tokens (740 characters)

**Analysis**:
- Shows hierarchical organization: Status → File → Failures → Summary
- File path shown once, then line numbers for each failure
- Error type and method clearly identified
- Only files with failures are shown (5 passing files omitted)

## Example 4: First-Failure Focus Mode

**Command**: `try --agent --agent-focus first-failure try/formatters/token_budget_try.rb`

**Output**:
```
FAIL: 10/37 tests (1 files, 0μs)

try/formatters/token_budget_try.rb:
  L32: NoMethodError: undefined method 'estimate_tokens' for nil
  ... (9 more failures not shown)

Summary: 27 passed, 0 failed, 10 errors in 1 files
```

**Token Count**: ~55 tokens (220 characters)

**Analysis**:
- Shows only first failure per file
- Explicit truncation notice: "... (9 more failures not shown)"
- 70% token reduction while preserving key debugging info
- Ideal for rapid triage across many files

## Example 5: Critical Focus Mode

**Command**: `try --agent --agent-focus critical try/formatters/token_budget_try.rb`

**Output**:
```
CRITICAL: 1 file with errors

try/formatters/token_budget_try.rb:
  L32: NoMethodError: undefined method 'estimate_tokens' for nil
  L36: NoMethodError: undefined method 'estimate_tokens' for nil
  L40: NoMethodError: undefined method 'estimate_tokens' for nil
  L45: NoMethodError: undefined method 'consume' for nil
  L48: NoMethodError: undefined method 'used' for nil
  L51: NoMethodError: undefined method 'remaining' for nil
  L56: NoMethodError: undefined method 'would_exceed?' for nil
  L60: NoMethodError: undefined method 'would_exceed?' for nil
  L66: NoMethodError: undefined method 'force_consume' for nil
  L70: NoMethodError: undefined method 'used' for nil
```

**Token Count**: ~170 tokens (680 characters)

**Analysis**:
- Focus on errors/exceptions only (ignores assertion failures)
- Header "CRITICAL:" clearly indicates severity
- All errors shown as they're all critical
- No summary line (not needed for critical-only view)

## Example 6: Token-Limited Output

**Command**: `try --agent --agent-limit 1000 try/formatters/agent_formatter_try.rb`

**Output**:
```
PASS: 21 tests (1 files, 0μs)

Summary: 21 passed, 0 failed in 1 files
```

**Token Count**: ~15 tokens (well under 1000 limit)

**Analysis**:
- Same as standard for passing tests (no truncation needed)
- Token limit would apply to failure details if present
- Truncation preserves most important information first

## Verbose Mode Comparison

**Command**: `try -v try/formatters/agent_formatter_try.rb` (first 20 lines)

**Output**:
```
======================================================================
                          PROCESSING 1 FILES
======================================================================

  ----------------------------------------------------------------------
  >>>>>  try/formatters/agent_formatter_try.rb  <<<<<<<<<<<<<<<<<<<<<<<<
  ----------------------------------------------------------------------
    Executing global setup (lines 3..5)
    Test 1/21: Test TokenBudget initialization and basic functionality

    PASSED @ try/formatters/agent_formatter_try.rb:10
          7: ## Test TokenBudget initialization and basic functionality
          8: @budget = Tryouts::CLI::TokenBudget.new(100)
          9: @budget.limit
         10: #=> 100

    Test 2/21: Unnamed test

    PASSED @ try/formatters/agent_formatter_try.rb:13
         12: @budget.used
         13: #=> 0
...
```

**Full Token Count**: ~1400 tokens (5600 characters)

**Compression Ratio**: Agent mode = 15 tokens, Verbose = 1400 tokens
**Token Reduction**: 99% reduction (extreme case with all passing tests)

## Token Efficiency Analysis

### Format Comparison
| Mode | Tokens | Characters | Reduction vs Verbose |
|------|--------|------------|----------------------|
| Verbose | 1400 | 5600 | 0% (baseline) |
| Agent (standard) | 15 | 60 | 99% |
| Summary | 6 | 25 | 99.6% |
| First-failure | 55 | 220 | 96% |
| Critical | 170 | 680 | 88% |

### Token Allocation Efficiency
For mixed results (104 tests, 10 failures):
- Status information: ~10 tokens (5%)
- Failure details: ~160 tokens (87%)
- Summary: ~15 tokens (8%)

This closely matches the TOPA algorithm allocation strategy:
- Summary: 20% of budget
- Failures: 60% of budget
- Context: 15% of budget
- Buffer: 5% of budget

## Structural Patterns

### Status Line Format
```
STATUS: count/total tests (file_count files, timing)
```
Examples:
- `PASS: 21 tests (1 files, 0μs)`
- `FAIL: 10/104 tests (6 files, 0μs)`

### File Section Format
```
file_path:
  L{line}: {error_type}: {error_message}
  L{line}: expected {expected}, got {actual}
```

### Summary Line Format
```
Summary: {passed} passed, {failed} failed[, {errors} errors] in {files} files
```

## Key Design Decisions

### Token Efficiency Strategies
1. **Relative Paths**: `try/formatters/file.rb` instead of `/full/path/to/try/formatters/file.rb`
2. **Minimal Timing**: `0μs` instead of `0.000001 seconds`
3. **No Redundancy**: File path shown once, line numbers L32, L36 vs full paths
4. **Smart Aggregation**: "... (9 more failures not shown)" vs listing all

### Semantic Preservation
1. **Line Numbers**: Always preserved for debugging
2. **Error Types**: Full class names preserved (NoMethodError)
3. **Method Names**: Critical debugging info preserved
4. **Status Context**: Pass/fail status always clear

### Progressive Disclosure
1. **Summary**: Just counts and status
2. **First-failure**: One representative failure per file
3. **Standard**: All failures within budget
4. **Critical**: All errors/exceptions regardless of budget

## Validation Criteria

### Format Consistency
- Status line always present and first
- File sections hierarchically organized
- Summary line always present and last (except critical mode)
- No ANSI colors or formatting

### Information Preservation
- Essential debugging info never truncated
- Failure causation always clear
- File locations always precise
- Error types always specific

### Token Efficiency
- Achieve 60-80% reduction vs traditional verbose output
- Scale efficiently with test suite size
- Respect token budget limits consistently
- Provide meaningful truncation notices

## Implementation Notes

This format successfully demonstrates:
1. **Cross-language applicability**: Structure works for any test framework
2. **Scalability**: Efficient for 1 test or 10,000 tests
3. **Debugging utility**: Preserves essential information for fixing issues
4. **Token awareness**: Respects LLM context window constraints
5. **Focus flexibility**: Multiple modes for different use cases

The TOPA standard should maintain these characteristics while adapting to different programming languages and test frameworks.
