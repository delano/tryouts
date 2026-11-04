# Tryouts syntax and parser review (2026-11)

Branch `claude/relaxed-albattani-abdqts` at d94722b, Ruby 3.3.6. Baseline: `try/core try/expectations try/formatters try/translators try/regressions try/safety` all pass (41 files).

This review is deliberately narrower than the two October audits in this directory. Those catalogue ordinary defects (exit codes, translators, parallel races, stale `result`, dead code) and nothing in them has been fixed since, so they still stand. This document is about the thing they do not cover: the shape of the testfile language, the three-layer parser that implements it, and the gap between the two. Every behaviour claimed below was reproduced with a fixture; the fixtures were not committed.

## 1. The tension, stated precisely

A tryouts file *looks* like a script and the README promises it "behaves like a Ruby script executing top-to-bottom". The implementation is three layers that each know nothing about scripts:

1. **Line tokenizer** (`enhanced_parser.rb`). Every physical line becomes one token. Prism is used only to decide which lines hold comments and which comments sit inside a multi-line statement. Comment text is then classified by a cascade of 15 regexes.
2. **Block grouper** (`shared_methods.rb#group_into_test_blocks`). A state machine over the token stream: "code after expectations starts a new block", "description after code starts a new block if a code+expectation pair follows somewhere before the next description".
3. **Positional classifier** (`classify_blocks`). Block 0 without expectations is *setup*. The last block without expectations is *teardown*. Everything else without expectations is an *orphan*. Blocks with expectations are tests.

The execution side then re-derives script semantics on top of that: shared mode evaluates every block against one reused `Binding`, orphan blocks are run in source order, and fresh mode copies instance variables around. Each of those is a patch that makes one symptom go away. The underlying model is still "a test is a block of lines that happens to end in a comment", and the symptoms below all come from the same place: *the parser has no notion of a statement, and the executor has no notion of a statement's value*.

### Reproduced symptoms

| # | Fixture (abridged) | What happens | Why |
|---|---|---|---|
| S1 | `1 + 1 #=> 2` on one line | Silently becomes **setup code**. 0 tests, exit 0. | A comment at column > 0 is "inline" and is never classified. The IRB/xmpfilter idiom, the single most natural thing to write, is the one form the parser cannot see. |
| S2 | `if true` / `  1 + 1` / `  #=> 3` / `end` | Silently dropped. `✓ 0 tests passed`, exit 0. | Same column rule. (October workflow audit also notes this.) |
| S3 | `x = 41` / `x + 1` / `#=> x + 1` | **Fails**: `undefined local variable x`. | Test code runs via `Binding#eval` (locals persist), but expectations run via `instance_eval` on the container, a fresh scope. The expression can see `@ivars` and `result`, not the locals one line above it. |
| S4 | setup `setup_local = 1`, then a test reads it | **Passes** in shared mode. | Shared mode reuses one Binding, so locals *do* persist across sections. CLAUDE.md, `--help` and the README all say they don't. The docs describe the v3 behaviour; the code implements something closer to a script. |
| S5 | `container.class` in a test | `Object`. `binding.local_variables` includes `:container`. | `acquire_container_binding(container)` uses `instance_eval('binding')`, which captures the *caller's* local scope. The executor's own method argument leaks into every shared-context file. |
| S6 | `42 #=> 42`, then `nil #==> result == 42` | **Passes**. | `result`/`_` are singleton methods redefined only when the new value is truthy (`base.rb:72`). Known from October; included because the fix falls out of S3's fix. |
| S7 | `raise ... #=!> ArgumentError`, later test `error.message` | **Passes**, returns `"boom"`. | `define_singleton_method(:error)` is never removed. |
| S8 | `"abc"` / `#=> "abc"` / `#=> raise("x")` | Failure is reported `@ file:3`, the *first* expectation's line. | `eval_expectation_content` evaluates every expectation with `line_range.first + 1`. A raise inside expectation N has no usable backtrace line. |
| S9 | `## First line` / `## second line` / code / `#=>` | Description is `second line`. | `has_following_test_pattern?` breaks on the second `:description` token before finding code, so the first line is demoted to a comment. The continuation branch is unreachable for the common case. (October #11.) |
| S10 | setup, blank, `# This comment shows what happens when ...`, `@b = 2`, `#=> 2` | The plain `#` comment becomes the **test description**. | `classify_potential_descriptions_with_boundaries` promotes a single-`#` comment to a description if it is longer than 10 chars and matches `/test\|example\|demonstrate\|show\|should\|when\|given/i`. An English-word heuristic decides test boundaries. Under `--strict` the file is rejected at a *different* line (the next unnamed test), so the user is pointed away from the comment that was silently promoted. |
| S11 | `require 'set'` / `@r = Set.new` / `@r << :a` / `@r.include?(:a)` / `#=> true` | The whole prologue is **test 1** with four code lines; there is no setup section. | Block 0 has an expectation, so it is a test. The first `#=>` in a file swallows everything above it. `--strict` rejects it with "unnamed test at line 1", which is correct but not the diagnosis a reader needs ("your setup has no `##` between it and the first expectation"). |
| S12 | `@list = []` in setup; test 1 `@list << 1`; test 2 `@list.size #=> 0` under `--no-shared-context` | **Fails**: size is 1. | Fresh context copies instance variable *references* from the setup container. Mutable state is shared. "Fresh" is only fresh for reassignment. |
| S13 | one test, then `puts "x"` / `@after = 1` at the end of file | Runs as **teardown**. Add one more test below it and the same two lines become an **orphan block** with different failure semantics (orphan failure aborts the batch; teardown failure is logged and ignored). | Meaning is assigned by position, not by what the code is. |
| S14 | `# => see the README` anywhere in setup | Is an **expectation** (`^#\s*=>` admits the space), so the setup becomes a test. | The Ruby documentation idiom `# => value` is indistinguishable from `#=>`. That is arguably a feature for S1, and a trap for prose. |
| S15 | `"123" #=<> /\d+/` | **Passes**. | `#=<>` only inverts `==`; `"123" == /\d+/` is false, so "intentional failure" succeeds. README's own example `#=<> result.include?(4)` passes regardless of contents. (October #16.) |
| S16 | `[1,2,3] #=%> result * 2` | **Passes**. | Inside `#=%>`, `result` is the elapsed time, not the value. The documented example is a tautology. (October #17.) |

S1, S3, S4, S5, S8, S10, S11, S12, S13 and S14 are not in the October audits.

## 2. Logic bugs, cruft and inefficiencies in the parser path

Beyond the symptoms above, in reading order through the parse:

- **`parse_ruby_line` is called for every code line and every expectation**, and the `ast:` it produces is never read anywhere in `lib/`. Measured: a full parse of the 54-file suite is 115 ms per pass; the per-line `Prism.parse` of one 775-line file costs 3.4 ms against 1.7 ms for the whole-file parse the constructor already does. Delete it and `parse_expectation`.
- **Three separate line-exclusion mechanisms** exist because the tokenizer has no statement model: `multiline_comment_spans` (for `=begin/=end`), `multiline_statement_ranges` plus `strictly_inside_multiline_statement?` (for column-0 comments inside an unclosed literal), and the `start_column > 0` rule (for inline). Each is a linear scan per line (`any?` over spans, `any?` over ranges), so classification is O(lines × multiline nodes). Fine for a 300-line file, wasteful for `familia`-sized ones, and all three vanish under the approach in section 4.
- **`classify_potential_descriptions_with_boundaries` slices `tokens[(index + 1)..]`** for every single-`#` comment that passes the word regex. That is an O(n) array copy per candidate, so O(n²) for comment-heavy files. It also means the "test window" is the next five *tokens*, so a description followed by a six-line method body is not a description.
- **`find_test_case_boundaries` and `has_following_test_pattern?` both forward-scan from every description.** They compute overlapping information (where does the test after this description end?) with different stopping rules, which is how S9 happens: one of them breaks on the next `:description`, the other does not care.
- **`group_into_test_blocks` has twelve textually identical `in [_, { type: :xxx_expectation }]` arms.** `is_expectation_type?` already exists and allocates a 12-element array on every call. One arm with a guard, and a frozen `Set`, replaces all of it.
- **`add_context_to_block` files comment and blank tokens into `block[:code]`** when the block has no expectations yet. `positioned_code_tokens` filters them back out, but `calculate_end_line` does not, so a setup block's `end_line` (and therefore `--inspect`'s `Range:`) includes trailing blank lines and comments. `--inspect` also prints 0-based ranges to a user whose editor is 1-based.
- **`## TEST:` keeps its prefix, `# TEST:` strips it.** `/^##\s*(.*)$/` matches first, so descriptions read `TEST: Feature` in every formatter, while the `# TEST:` form yields `Feature`. Pick one.
- **The `## =>` branch at `enhanced_parser.rb:256` is unreachable** (`^##` matches earlier). The October workflow audit shows this turns 17 translator tests into assertion-free orphan blocks; that is a coverage hole in this repo's own suite, not just dead code.
- **`TestCase#source_lines` copies `@lines[start..end]` into every test case** and `TestCaseResultPacket` is rebuilt field-by-field in `execute_single_test` to add `captured_output`; `Data#with(captured_output:)` is the one-liner.
- **`should_display_test_result?` does a `require_relative` inside the per-test path** and is called three times per test.
- **`execution_phase` is emitted twice per file** (`test_batch.rb:85` and `:177`), with different counts, so formatters see two `EXECUTING N TESTS` headers.
- **`TestBatch#initialize` builds a `FormatterFactory.create_formatter`** it never uses; the real formatter lives in `@output_manager`.
- **Evaluation line numbers are wrong twice over.** Test code is anchored correctly now (`first_code_line`), but expectations are anchored at the block start (S8) and the translator paths pass no line at all for expectations.
- **`Timeout.timeout` wraps expectation evaluation but not the `#=!>` code path** (October). Separately: the per-test timeout is a thread-raising `Timeout`, which can interrupt test code mid-`ensure`. A `Process.clock_gettime` budget checked between statements is only cooperative monitoring: it cannot stop a statement that never returns or a blocking call, and under section 4.3 a test case runs as one evaluation, so there are no checkpoints inside it. Keep an independently enforced deadline per test (the thread-raising one, or a watchdog thread) so a run stays bounded, and use the clock only to report elapsed time.
- **Fresh mode is three different things**: setup runs in `@setup_container` via `instance_eval`; tests run in `Object.new` with ivars shallow-copied in (S12); teardown runs in `@container`, which never saw setup (October #10); orphans run in `@setup_container`. There is no single sentence that describes what "fresh" means.

## 3. Syntax: what to tighten

The expectation family is a good idea and worth keeping. The problems are at the edges, where each operator has grown its own private rules for what `result` means and what counts as a match.

### 3.1 One rule for `result`, `_` and `error`

Today `result` is the value, except in `#=%>` where it is a float of milliseconds (S16), except after a raise where it is the exception object handed to `#=:>` and `#=~>` (which silently retargets to `error.message`). Proposed invariant:

- `result` / `_` is **always** the value of the subject statement. If the subject raised, `result` is `nil`.
- `error` is the exception the subject raised, or `nil`. It is bound per test, never left behind (S7).
- `#=%>` gets its own name for the measurement (`elapsed_ms` or similar) and the bare-number form `#=%> 15` keeps working as a threshold. `#=%> result * 2` becomes a real expression about the value, or a parse warning.
- Every form that evaluates an expression sees the subject's local variables (S3), because the expression is evaluated in the same binding as the code (section 4.3).

### 3.2 Each operator does one thing

| Operator | Today | Proposed |
|---|---|---|
| `#=>` | `==` | unchanged |
| `#==>` / `#=/=>` / `#=\|>` | strict `true` / strict `false` / boolean | unchanged; these are the clearest of the set |
| `#=:>` | `is_a?` with a fallback to `Object.const_get` on `NameError` | unchanged semantics, drop the fallback once expressions run in the file's binding (constants resolve naturally) |
| `#=~>` | `=~` against `result.to_s`, or `error.message` if the result is an exception | match against `result.to_s` only; exception messages are written explicitly as `#=~> ... ` after `#=!>` **with** `error` in scope, e.g. `#==> error.message.match?(/x/)` or keep a documented `#=~>` auto-target but only when `error` is non-nil and `result` is nil |
| `#=!>` | passes if `expected.is_a?(Class)` and `error.is_a?(expected)`, or if the expression is truthy | Class/Module form only (`is_a?(Module)` so `#=!> Comparable` works, October #18); truthy expressions move to `#==>` which already exists. Fails, never re-executes, when nothing was raised |
| `#=*>` | non-nil; any text after the arrow is parsed and discarded | keep, but warn on trailing text, or treat `#=*>` as sugar for `#==> !result.nil?` |
| `#=<>` | inverts `#=>` only, documented as "intentional failure" | either rename to what it is (`#=!=>` or "must not equal") or make it a true negation of whatever follows (`#=<> /\d+/` means "must not match"). The README examples currently pass vacuously (S15) |
| `#=1>` / `#=2>` | `include?` for strings, `=~` for regexes | unchanged, but document that a String is a substring test |

### 3.3 Descriptions and boundaries

- `##` is the description marker. Drop `# TEST:` (two spellings for one thing) and drop the single-`#` English-word heuristic entirely (S10). A single `#` is a comment, full stop. That removes `potential_description`, `classify_potential_descriptions_with_boundaries`, `find_test_case_boundaries` and `find_test_case_end`.
- Consecutive `##` lines join into one description (S9).
- Strip or keep the `TEST:` prefix consistently. Recommendation: keep whatever the author wrote; do not special-case the word.
- Support the inline form `expr #=> value` (S1). This is how Ruby documentation, IRB transcripts and every blog post already write it, and tryouts' whole pitch is that the file *is* documentation. Under the statement model it is free: a trailing comment on a statement's last line is that statement's expectation.
- Make `# =>` (with space) deliberately equivalent to `#=>` and say so, or deliberately not. Today it is equivalent by accident of regex (S14). Recommendation: equivalent, because it is the doc idiom, with a warning when it appears above the first `##` so prose in a setup comment cannot silently create a test (S11, S14).
- Setup and teardown are defined as "statements before the first described test" and "statements after the last expectation", and the three-way position-dependent meaning of bare code (S13) collapses to one: bare code runs in order, in the shared binding, and is reported under whichever section it falls in. A raise in any of them aborts the file the same way.

### 3.4 Say what the execution model is, once

Docs currently contradict each other (S4). Write the sentence and make the code match it:

> A tryouts file is a Ruby script. It is executed top to bottom in one binding. Local and instance variables persist from each line to the next. An expectation comment asserts something about the value of the statement immediately above it. A `##` comment names the group of statements that ends at the next expectation, for reporting only.

Fresh context then has an honest definition too: "re-run everything above the first `##` in a new binding before each test". If that is not worth implementing, retire the flag rather than keep the current approximation (S12 and October #10).

## 4. An alternative parser: statement-anchored, not line-anchored

The constructor already does `Prism.parse(@source)`. That result contains every top-level statement with exact byte and line locations, and every comment with the same. Nothing else is needed.

### 4.1 Algorithm

```ruby
result   = Prism.parse(source)
stmts    = result.value.statements.body          # top-level statements, in order
comments = result.comments                       # every comment, with locations

# 0. Give each statement its full extent. A statement's location ends at a heredoc's
#    *opener* (`<<~TEXT`), not at its terminator, so widen the end to the furthest
#    closing_loc of any heredoc node inside it. A statement that starts inside the
#    previous one's widened extent (`a = <<~A; b = 1`) shares the opener line; merge
#    the two into one unit.
#
# 1. Attach each comment to a slot, by its offset against the widened extents:
#    - starts after a statement's own code on that statement's last code line
#                                       -> trailing comment of that statement
#    - between the end of stmt[i] and the start of stmt[i+1]
#                                       -> gap i (after stmt i)
#    - after the last statement (i = n-1, up to end of file or __END__)
#                                       -> gap n-1, the terminal gap
#    - before stmt[0]                   -> the leading gap (gap -1)
#    - anywhere else inside a statement's extent (a method, class or block body)
#                                       -> internal comment of that statement
#    Text inside string literals and heredoc bodies is not in result.comments at all;
#    real comments inside method, class and block bodies are, and land in the last case.
#
# 2. Classify each comment: expectations (/\A#\s*=\S*>/), descriptions (/\A##/),
#    everything else (prose). Internal comments are never expectations; an
#    expectation-shaped one produces the S2 warning ("expectation inside a statement
#    body at line N, not evaluated") instead of being dropped.
#
# 3. Expectations in gap i (the terminal gap included), plus trailing expectation
#    comments on stmt i, are assertions about the value of stmt i. stmt i is the
#    *subject*. An expectation in the leading gap has no statement above it: warn,
#    and report it as a failing test of its own.
#
# 4. Test cases, in order. Let prev be the previous subject's index, or -1 for the first
#    test. A test case for subject s starts after the nearest ## description in gaps
#    prev .. s-1 (for the first test, the leading gap counts as gap -1), and ends at s.
#    Gap prev also holds the previous subject's expectations; only descriptions written
#    after them count, so a ## above a #=> never names the test above it.
#    The statements from prev+1 up to that description are not part of the test:
#    for the first test they are the setup, for later tests an interlude that runs in
#    order before the test. A test with no ## in those gaps is unnamed and starts right
#    after prev, so an unnamed first test starts at stmt 0 and the file has no setup;
#    strict mode rejects it at the subject's line, saying the setup has no ## between it
#    and the first expectation (S11).
#
# 5. With no subjects at all, every statement is setup. Statements after the last
#    subject are teardown. Setup, interludes and teardown are just statements and
#    execute in order with the tests.
```

Prism 1.x ships `ParseResult#attach_comments!` (`node.location.leading_comments` / `trailing_comments`). In a prototype against this branch's Prism it attaches `#=>` lines as *leading* comments of the next statement and same-line comments as *trailing*, but it attaches by node location, so it neither widens heredoc extents (step 0) nor gives the terminal gap or internal comments their own slots. A single sorted pass over `result.comments` against the widened extents is simpler and covers all five cases.

### 4.2 What it removes

Compared with today's `enhanced_parser.rb` + `shared_methods.rb` (about 840 lines):

- No per-line regex pass. No `tokenize_content_with_inhouse_extraction`, `multiline_comment_spans`, `multiline_statement_ranges`, `strictly_inside_multiline_statement?`, `parse_ruby_line`.
- No `potential_description` and none of the four boundary-guessing functions.
- No `group_into_test_blocks` state machine, no `classify_blocks` by index, no `calculate_end_line`, no `extract_code_content` line-padding reconstruction: code for a test case is `source.byteslice(first.start_offset, last.end_offset - first.start_offset)` over the widened extents from step 0, so a subject ending in a heredoc includes its body and terminator, and its start line is `first.start_line`. Backtraces are right by construction. (A slice that stops at Prism's own `end_offset` ends at `<<~TEXT` and is not valid Ruby; `try/debug/complex_line_number_try.rb` has such a test.)
- S1, S2 (an indented `#=>` is inside a statement, so it is not a top-level gap comment; emit "expectation inside a statement body at line N" instead of silence), S9, S10, S11 (an expectation with no `##` above it since the previous subject is an unnamed test, and the warning can say exactly which statement it is attached to), S13 and S14 (a `# =>` above the first statement can be warned about specifically) are all handled by the data model rather than by special cases.

### 4.3 Execution under the same model

Keep one `Binding` per file in shared mode. Evaluate **per test case** (the statement run), not per line, so that `begin/rescue` and multi-statement examples stay atomic and the timeout and rescue wrapping stay where they are. Then evaluate each expectation **in the same binding** by compiling it into a lambda:

```ruby
value  = binding.eval(code, path, start_line)              # the subject's value
check  = binding.eval("->(result, _, error) { (\n#{expr}\n) }", path, expectation_line - 1)
check.call(value, value, raised_or_nil)
```

The expression goes on a line of its own: expectations can carry a trailing comment (`try/expectations/multiple_expectations_try.rb:14-16`), which on one line would comment out the closing brace. The parentheses make a stray `}` in the expression a syntax error rather than the end of the lambda, and starting the eval one line early keeps the expression on its own line number.

Verified on this branch: the lambda sees the test's locals (`x` in S3), `result` and `error` are true locals that cannot go stale (S6, S7), no singleton methods are defined on the container, and the expectation line is what the backtrace reports (S8). `#=%>` passes `elapsed_ms` the same way. Fix S5 at the same time by acquiring the binding from a method with no parameters, or via `TOPLEVEL_BINDING.dup`-style isolation with `self` swapped using `instance_exec`.

Fresh mode, if kept, becomes: build a new binding, evaluate the setup statement run into it, evaluate the test, discard. No instance-variable copying (S12 goes away), teardown runs in the last binding so it sees setup state (October #10).

### 4.4 Costs and risks

- Prism must parse the whole file successfully. It already must (`handle_syntax_errors` raises on `@prism_result.failure?`), so nothing changes there.
- Top-level `def`/`class` bodies containing `#=>` comments: they are inside a statement, so they are not expectations. Today a column-0 `#=>` inside a `class ... end` is *also* forced to a comment by `strictly_inside_multiline_statement?`, so behaviour is unchanged, but it becomes a warning instead of silent.
- `__END__` data, `BEGIN {}` blocks and `=begin/=end` are all represented in the parse result; none need special handling.
- Files that relied on the English-word heuristic to name tests will become unnamed tests under `--strict`. The repo's own suite has at least one (`try/core/single_hash_test_try.rb`). That is the desired outcome, but it is a migration step.
- The translators consume `Testrun`, `TestCase`, `Setup`, `Teardown`, `OrphanBlock`. Under the new model `OrphanBlock` disappears (bare statements are just part of the preceding or following case's run). Keeping the `Testrun` shape stable while changing what fills it is straightforward; dropping `OrphanBlock` is a small translator edit.

### 4.5 A smaller intermediate step

If a parser rewrite is too much at once, three changes to the current code remove most of the sharpest edges without changing the data model:

1. Delete `parse_ruby_line` and the `ast:` keys (pure cruft, measured 35 to 40 percent of parse time).
2. Delete the `potential_description` heuristic; single `#` is a comment.
3. Treat a comment with only whitespace before it on its line as column 0 (S2), and a trailing `#=>`-shaped comment on a code line as an expectation on that line (S1).

And two changes on the execution side:

4. Evaluate expectations through the binding-lambda form in 4.3 rather than `instance_eval` + singleton methods. This fixes S3, S5 (with the no-argument binding acquisition), S6, S7 and S8 together, and it removes the `Object.const_get` fallback in `result_type.rb`.
5. Write the one-sentence execution model from 3.4 into `--help`, README and CLAUDE.md, and delete the sentences that contradict it.

## 5. Suggested order

1. Section 4.5 items 1, 2, 4, 5. Small diffs, large reduction in spooky behaviour, no syntax change.
2. The operator clean-ups in 3.2 that are pure bug fixes (`#=!>` module check and no re-execution, `#=*>` trailing text, `#=<>` semantics, `#=%>` `result` shadowing). Each one has an existing October finding with a reproduction.
3. Inline `expr #=> value` support (item 3 of 4.5, or via the statement parser).
4. The statement-anchored parser, behind the existing `--enhanced-parser`-style flag for one release, then as the default. It is the only change here that makes the parser smaller instead of bigger.
5. Decide fresh context: define it as "re-run setup per test" or remove the flag.
