# docs/about-shared-or-fresh-context.md

---

# TestBatch Context Modes Fix

## Problem
The test `try/utilities/test_context_modes_try.rb` was failing because it expected `TestBatch` objects to expose their context objects via a `@shared_context` instance variable, but this didn't exist in the implementation.

### Failed Test
```ruby
## TEST: Context modes are different
testrun = @parser.parse
batch_shared = Tryouts::TestBatch.new(testrun, shared_context: true)
batch_fresh = Tryouts::TestBatch.new(testrun, shared_context: false)

contextA = batch_fresh.instance_variable_get(:@shared_context)
contextB = batch_shared.instance_variable_get(:@shared_context)

!(contextA.nil? && contextB.nil?) && contextA != contextB
#=> true
```

**Expected**: `true` (contexts should be different objects)
**Actual**: `false` (both contexts were `nil`)

## Root Cause
The `TestBatch` class had:
- `@container` - execution context for shared mode
- `@options[:shared_context]` - boolean flag
- No `@shared_context` instance variable to expose the context strategy

## Solution
Added a `@shared_context` instance variable that exposes different context strategies:

### 1. Added FreshContextFactory Class
```ruby
class FreshContextFactory
  def initialize
    @containers_created = 0
  end

  def create_container
    @containers_created += 1
    Object.new
  end

  def containers_created_count
    @containers_created
  end
end
```

### 2. Modified TestBatch#initialize
```ruby
def initialize(testrun, **options)
  # ... existing code ...

  # Expose context objects for testing - different strategies for each mode
  @shared_context = if options[:shared_context]
                      @container  # Shared mode: single container reused across tests
                    else
                      FreshContextFactory.new  # Fresh mode: factory that creates new containers
                    end
end
```

### 3. Updated Fresh Context Execution
```ruby
def execute_with_fresh_context(test_case)
  fresh_container = if @shared_context.is_a?(FreshContextFactory)
                      @shared_context.create_container
                    else
                      Object.new  # Fallback for backwards compatibility
                    end
  # ... rest of method unchanged ...
end
```

## Architecture Benefits

### Clear Context Strategy Exposure
- **Shared context mode**: `@shared_context` points to the single shared container
- **Fresh context mode**: `@shared_context` points to a factory that creates new containers
- Tests can now verify that different strategies are used

### Backwards Compatibility
- Existing functionality unchanged
- Added fallback for direct `Object.new` creation
- No breaking changes to public API

### Better Testability
- Context strategies are now introspectable
- Factory pattern allows tracking container creation
- Clear separation between shared vs fresh execution modes

## Test Results
```bash
✓ 5 tests passed
Completed in 2ms
```

All tests now pass consistently. The fix correctly exposes the different context handling strategies while maintaining full backwards compatibility.

## Technical Notes
- Uses factory pattern for fresh context creation
- Maintains single shared container for shared mode
- Type checking with `is_a?(FreshContextFactory)` for safe delegation
- Zero impact on existing execution logic
