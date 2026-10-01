# Tryouts v4.0.0.pre1 Audit (2026-09-28 @ 511f2e4)

**Headline:** 41 verified findings (11 high). The biggest problem is that the exit code can't be trusted: `--rspec` always exits 0, failure counts wrap modulo 256, and several expectation paths pass without checking anything.

## Severity summary

| Dimension        | High | Medium | Low | Total |
|------------------|-----:|-------:|----:|------:|
| Security         |    1 |      2 |   2 |     5 |
| Correctness      |    4 |      6 |   2 |    12 |
| Test coverage    |    5 |      6 |   0 |    11 |
| Dead code        |    1 |      5 |   6 |    12 |
| Dependency risk  |    0 |      0 |   1 |     1 |
| **Total**        | **11** | **19** | **11** | **41** |

### Root causes reported more than once

Some defects were found independently in more than one dimension. Each copy is kept below, but these are the distinct bugs to fix:

| Root cause | Reported in |
|---|---|
| `execute_rspec_mode` ignores `RSpec::Core::Runner.run`'s status and returns 0 | Security, Correctness, Test coverage (anchored at `test_executor.rb` lines 302, 323 and 88; the verifiers gave different line numbers for the same method) |
| `result`/`_` not redefined for nil/false results (`base.rb:71`) | Correctness, Test coverage |
| `#=!>` test body runs outside `execute_with_timeout` (`test_batch.rb:308`) | Security, Test coverage |
| `rescue SystemExit, SignalException` swallows Interrupt/SIGTERM (`test_batch.rb:363`) | Security, Test coverage |
| `#=!>` with no exception re-runs the test code (`exception.rb`) | Correctness, Test coverage |
| `handle_file_error` references undefined `file`/`ex` (`test_runner.rb:208`) | Correctness, Test coverage, Dead code |
| `future.value` returns nil on rejection (`test_runner.rb:139`) | Correctness, Test coverage |
| Unreachable `##=>` parser branch (`enhanced_parser.rb:256`) | Test coverage, Dead code |

---

## Security

### HIGH: `--rspec` mode always exits 0
- **Location:** `lib/tryouts/test_executor.rb:302`
- **Category:** exit-code-accuracy
- **Why it matters:** `execute_rspec_mode` ignores the status from `RSpec::Core::Runner.run([])` and returns 0. TestRunner adds these per-file results into the process exit code, so `try --rspec` exits 0 even when tests fail. We confirmed this by running `1 #=> 2` under `--rspec`: RSpec prints the failure, but the process exits 0. Direct mode exits 1. Any CI gate that uses the translation path is silently bypassed. Minitest mode only works because the `at_exit` hook in `minitest/autorun` overrides the exit status.
- **Suggested fix:** Use the runner's status: `status = RSpec::Core::Runner.run([]); status.zero? ? 0 : 1`, and feed it into the aggregator so the grand totals and exit code match. For Minitest, call `Minitest.run` explicitly and return its boolean.
- **Consensus:** 3/3 verifiers

### MEDIUM: Exit status wraps modulo 256
- **Location:** `exe/try:93`
- **Category:** exit-code-accuracy
- **Why it matters:** `exit cli.run(...)` uses the raw failure count as the exit status, and POSIX keeps only the low 8 bits. We confirmed that 26 files totalling exactly 256 failures print `Total: 256 failed` and exit 0. The circuit breaker caps failures at 10 per file, but a full suite can easily reach 256.
- **Suggested fix:** `exit [cli.run(files, **options), 255].min`, or `exit(count.zero? ? 0 : 1)`. Update the exit-code contract in README/CLAUDE.md to match.
- **Consensus:** 3/3 verifiers

### MEDIUM: A hanging `#=!>` test blocks the run indefinitely
- **Location:** `lib/tryouts/test_batch.rb:308`
- **Category:** denial-of-service
- **Why it matters:** For exception expectations, `eval_code` runs before the `execute_with_timeout` block at line 317, and that block only wraps expectation evaluation. With `#=> 1`, a `loop { sleep 0.1 }` test times out after 30s. With `#=!> RuntimeError`, the same loop was still running at 45s. Combined with the signal-swallowing issue below, one stuck test can hang a CI runner until the job is killed.
- **Suggested fix:** Put the eval inside the timeout block (lines 305-315), and treat `Timeout::Error` as an error result rather than as a caught test exception.
- **Consensus:** 3/3 verifiers

### LOW: SIGINT/SIGTERM become test errors and the run keeps going
- **Location:** `lib/tryouts/test_batch.rb:363` (also lines 521, 568, 620, 669)
- **Category:** signal-handling
- **Why it matters:** `rescue SystemExit, SignalException` catches Interrupt and SIGTERM. In testing, a SIGINT was recorded as `StandardError: Test terminated by Interrupt` and the next test still ran. Ctrl-C does not stop a suite, and a CI cancellation can be ignored until the platform sends SIGKILL, which also skips teardown.
- **Suggested fix:** Rescue only `SystemExit`. Let `SignalException`/`Interrupt` propagate, or re-raise them after recording the error, and run teardown from an `ensure`.
- **Consensus:** 3/3 verifiers

### LOW: `.` and `../lib` are put on `$LOAD_PATH` before lazy requires
- **Location:** `exe/try:38`
- **Category:** insecure-default
- **Why it matters:** `{lib,../lib,.}` is unshifted onto `$LOAD_PATH`, and some gems are required only later, at runtime: `minitest/test`, `rspec/core` and `minitest/autorun`. A file with the same name in the working tree or its parent directory shadows the real gem and gets executed. This happens even with `--inspect` and `--generate-*`, which are documented as not running tests. The added risk is modest, but it extends trust beyond `*_try.rb` files and beyond the current directory.
- **Suggested fix:** Keep only `lib`, or make load-path changes opt-in with an `-I` flag. Another option is to require these gems eagerly, before `update_load_path`.
- **Consensus:** 3/3 verifiers

---

## Correctness

### HIGH: `result`/`_` keep the previous test's value when the result is nil or false
- **Location:** `lib/tryouts/expectation_evaluators/base.rb:71`
- **Category:** correctness
- **Why it matters:** `elsif expectation_result.actual_result` is a truthiness check. When a test returns nil or false, the old singleton `result` stays on the shared container. We confirmed that after `5 #=> 5`, both `nil #==> result.nil?` and `false #==> result == false` fail. In fresh-context mode they raise NameError instead. The same bug can also make a wrong expectation pass.
- **Suggested fix:** Always redefine `result`/`_` when an `expectation_result` is supplied. Also reset `error` at the start of each test.
- **Consensus:** 3/3 verifiers

### HIGH: `--rspec` exits 0 on failing examples
- **Location:** `lib/tryouts/test_executor.rb:323`
- **Category:** exit-code
- **Why it matters:** This is the same root cause as the Security finding above. We confirmed `2 examples, 1 failure` with exit status 0, so CI using `--rspec` passes on red.
- **Suggested fix:** `status = RSpec::Core::Runner.run([]); status.zero? ? 0 : 1`. Record the failure in the aggregator, and call `RSpec.clear_examples` after each run.
- **Consensus:** 3/3 verifiers

### HIGH: AgentFormatter loses or misattributes results under `--parallel`
- **Location:** `lib/tryouts/cli/formatters/agent.rb:74`
- **Category:** concurrency
- **Why it matters:** The formatter stores one `@current_file_data` slot and shares it across worker threads, so parallel files overwrite each other. We confirmed with 4 files of 2 failures each: sequential `--agent` reports 8 failed, while `--agent -j 4` reports 2 failed, lists them under the wrong file, and shows descriptions from a different file. Agent mode is the output meant for automated consumers.
- **Suggested fix:** Keep per-file state keyed by path (`Concurrent::Map` or a Hash guarded by a Mutex), and look up the entry through `packet.test_case.path`. Alternatively, turn off parallel mode when the agent formatter is selected.
- **Consensus:** 3/3 verifiers

### HIGH: Non-StandardError exceptions from test code abort the whole run
- **Location:** `lib/tryouts/test_batch.rb:355`
- **Category:** error-handling
- **Why it matters:** The regular branch rescues only `StandardError`, so `raise NotImplementedError` (a ScriptError) escapes through TestBatch, FileProcessor, TestRunner and `exe/try`. The runner prints a raw backtrace, the remaining tests don't run, and no summary is printed.
- **Suggested fix:** Mirror line 309: `rescue StandardError, ScriptError, SystemStackError, SecurityError => ex`. Add `ScriptError` to `file_processor.rb:40` as a backstop.
- **Consensus:** 3/3 verifiers

### MEDIUM: A `#=!>` test that doesn't raise runs its code twice
- **Location:** `lib/tryouts/expectation_evaluators/exception.rb:123`
- **Category:** correctness
- **Why it matters:** When the code doesn't raise, `caught_exception` is nil and is not passed to the evaluator, so `execute_test_code_and_evaluate_exception` re-evaluates the code. That second run uses the wrong start line and bypasses the shared binding. We confirmed that `@count += 1 #=!> StandardError` leaves `@count == 2`. Side effects happen twice, and if the second run raises, the test can be reported as passing.
- **Suggested fix:** Always pass `caught_exception:` for exception expectations. When it is nil, return a failure reading "No exception was raised". Delete `execute_test_code_and_evaluate_exception`.
- **Consensus:** 3/3 verifiers

### MEDIUM: Indented `#=>`/`##` lines are silently dropped
- **Location:** `lib/tryouts/parsers/enhanced_parser.rb:138`
- **Category:** parser
- **Why it matters:** The parser treats `start_column > 0` as meaning a comment follows code on the same line, but a comment with only leading whitespace also matches. We confirmed that an indented test with a wrong expectation (`#=> 3` for `1 + 1`) is treated as setup code, never checked, and the run exits 0 with no warning.
- **Suggested fix:** Treat a comment as inline only if there is non-whitespace text before it on the line. Otherwise classify it as a normal comment, or warn that it looks like a malformed expectation.
- **Consensus:** 2/3 verifiers

### MEDIUM: Fresh-context teardown can't see setup's instance variables
- **Location:** `lib/tryouts/test_batch.rb:642`
- **Category:** correctness
- **Why it matters:** In fresh-context mode, setup runs in `@setup_container`, but teardown always runs in `@container`. We confirmed that under `--no-shared-context`, `@resource.upcase` in teardown fails with a nil error, so resources opened in setup can't be released.
- **Suggested fix:** `target = shared_context? ? @container : (@setup_container ||= Object.new)`.
- **Consensus:** 3/3 verifiers

### MEDIUM: Translators never check the exception class in `#=!> SomeError`
- **Location:** `lib/tryouts/translators/minitest_translator.rb:97` (also `rspec_translator.rb:283-284`)
- **Category:** correctness
- **Why it matters:** The generated tests only assert that the expectation is truthy, and a Class constant is always truthy. We confirmed that `raise ArgumentError #=!> TypeError` passes under both `--minitest` and `--rspec`. Also, `assert_raises(StandardError)` doesn't catch the ScriptError and SystemStackError cases that direct mode accepts.
- **Suggested fix:** If the evaluated value is a Class, use `assert_kind_of(expected, error)` or `expect(error).to be_a(expected)`; otherwise assert truthiness.
- **Consensus:** 3/3 verifiers

### MEDIUM: Translators silently skip every expectation type except `#=>` and `#=!>`
- **Location:** `lib/tryouts/translators/minitest_translator.rb:104` (also `rspec_translator.rb:290`)
- **Category:** correctness
- **Why it matters:** Tests whose expectations are all `#==>`, `#=:>`, `#=~>`, `#=%>`, `#=1>` and similar still become examples, but those examples contain no assertions and always pass. `#=<>` intentional failures pass too.
- **Suggested fix:** Translate each expectation type (`assert_equal true`, `assert_kind_of`, `assert_match`, `refute_nil`, `flunk`, `capture_io`), or `skip` loudly for types that aren't supported.
- **Consensus:** 3/3 verifiers

### MEDIUM: RSpec example groups accumulate across files
- **Location:** `lib/tryouts/test_executor.rb:322`
- **Category:** correctness
- **Why it matters:** `RSpec.world` is never cleared between files, so each file re-runs all earlier files' examples. The first file reports 1 example; the second reports 3. The number of runs grows as O(N²), side effects repeat, and failure counts are inflated.
- **Suggested fix:** Call `RSpec.clear_examples` after each run, or translate all files first and run RSpec once.
- **Consensus:** 3/3 verifiers

### LOW: `handle_file_error` raises NameError
- **Location:** `lib/tryouts/test_runner.rb:208`
- **Category:** correctness
- **Why it matters:** The method interpolates undefined locals `file` and `ex`, so any error that reaches this handler becomes a NameError. In sequential mode that NameError aborts the run instead of being counted as an infrastructure failure.
- **Suggested fix:** Change the signature to `handle_file_error(file, exception)` and update the call at line 175.
- **Consensus:** 2/3 verifiers

### LOW: A rejected future hides the real exception
- **Location:** `lib/tryouts/test_runner.rb:139`
- **Category:** error-handling
- **Why it matters:** `Concurrent::Future#value` returns nil when the task raised, so the code fails with `undefined method 'zero?' for nil` and the original error is lost. The failure is also never recorded as an infrastructure failure.
- **Suggested fix:** Use `future.value!`, or check `future.rejected?` and report `future.reason` through `add_infrastructure_failure`.
- **Consensus:** 3/3 verifiers

---

## Test coverage

### HIGH: No test covers `result`/`_` with nil or false results
- **Location:** `lib/tryouts/expectation_evaluators/base.rb:71`
- **Category:** correctness-untested
- **Why it matters:** This is the same bug as in Correctness. We confirmed that after `42 #=> 42`, both `false #==> result == false` and `nil #==> result.nil?` fail. Nothing under `try/` exercises falsy results with `result`.
- **Suggested fix:** Use `elsif expectation_result`. Add a shared-context tryout that has falsy-result tests right after a non-nil test.
- **Consensus:** 3/3 verifiers

### HIGH: The `#=!>` path has no timeout, and no test covers timeouts at all
- **Location:** `lib/tryouts/test_batch.rb:308`
- **Category:** timeout-coverage
- **Why it matters:** We confirmed with `test_timeout: 1` that `#=> 1` times out after 1.0s while `#=!> RuntimeError` never does. In addition, `test_timeout` is never passed from the CLI to `TestBatch.new` (`test_executor.rb:34-42`) and there is no flag for it, so `execute_with_timeout` (line 753) has no coverage.
- **Suggested fix:** Wrap the eval in the timeout. Pass `test_timeout` through from TestExecutor and add a `--timeout SECONDS` option. Add tryouts that set `test_timeout: 1` on both paths.
- **Consensus:** 3/3 verifiers

### HIGH: No test covers "exception expected, none raised"
- **Location:** `lib/tryouts/expectation_evaluators/exception.rb:29`
- **Category:** correctness-untested
- **Why it matters:** This is the double-execution bug from Correctness. We confirmed that `@count` ends at 2. The existing exception tests always raise, so this branch never runs under test.
- **Suggested fix:** Always pass `caught_exception:` and delete the fallback. Add a tryout that checks a counter increments exactly once.
- **Consensus:** 3/3 verifiers

### HIGH: No test checks exit codes in framework modes
- **Location:** `lib/tryouts/test_executor.rb:88`
- **Category:** exit-code
- **Why it matters:** This is the same root cause as the `--rspec` exit-0 finding. CI only runs `--rspec`/`--minitest` on passing files, and `try/translators` tests only `generate_code`/`translate` in isolation.
- **Suggested fix:** Return the runner's status. Add a regression tryout, modelled on `try/regressions/exit_code_fix_try.rb`, that runs `exe/try --rspec` on a failing file and asserts a non-zero `$?.exitstatus`.
- **Consensus:** 3/3 verifiers

### HIGH: `##=> true` turns 17 translator tests into orphan blocks with no assertions
- **Location:** `lib/tryouts/parsers/enhanced_parser.rb:256`
- **Category:** vacuous-tests
- **Why it matters:** The generic `^##` description branch at line 221 matches first, so `##=> true` becomes a description and the code before it is classified as an orphan block. `--inspect` shows only 9 of the 14 `## TEST:` blocks in `minitest_translator_try.rb` as test cases, plus orphan blocks of 67 and 57 lines. `rspec_translator_try.rb` has 12 more `##=>` lines. Most of the translator `generate_code` coverage is therefore illusory.
- **Suggested fix:** Move the `^##\s*=>` branch above the description branch, or remove it and warn about `##=>` lines. Then replace `##=> true` with `#=> true` in `try/translators/*.rb`, which should expose real translator bugs.
- **Consensus:** 2/3 verifiers

### MEDIUM: Minitest `generate_code` emits invalid assertions, and the tests lock that in
- **Location:** `lib/tryouts/translators/minitest_translator.rb:178` (also line 167)
- **Category:** correctness-untested
- **Why it matters:** The template interpolates the Expectation object instead of `expectation.content`, which produces `assert_equal #<data Tryouts::Expectation ...>`. Everything after `#` is a Ruby comment, so every generated assertion is silently dropped. `minitest_translator_try.rb` lines 263 and 373 assert this broken output as the "current behavior".
- **Suggested fix:** Use `expectation.content`. Fix the two tests, and add a test that parses the generated code with `Prism.parse` and asserts it has no errors.
- **Consensus:** 3/3 verifiers

### MEDIUM: No test covers signal behavior
- **Location:** `lib/tryouts/test_batch.rb:363`
- **Category:** signal-handling-untested
- **Why it matters:** We confirmed that a SIGINT during test 2 of 3 lets test 3 run and ends with `2/3 passed`. The existing tests cover only `exit`/`SystemExit`, and under `--parallel` a single Ctrl-C can't stop the worker threads.
- **Suggested fix:** Rescue only `SystemExit`, or re-raise signals. Add a test that sends SIGINT to `exe/try` and asserts that it exits promptly with a non-zero status.
- **Consensus:** 3/3 verifiers

### MEDIUM: The fresh-context test proves nothing
- **Location:** `lib/tryouts/test_batch.rb:279`
- **Category:** vacuous-tests
- **Why it matters:** `try/core/fresh_context_try.rb` uses `#==> true` for its six isolation checks, and those pass in any mode. We confirmed 14/14 passing in shared mode, even though the file says it should fail there. No CI job runs `--no-shared-context`, so lines 279-293 and the fresh-mode orphan-block path (lines 452-456) are effectively untested.
- **Suggested fix:** Change those lines to `#=> true`, or to `#==> @isolated_var.nil?`. Add a CI step that runs the file in fresh mode.
- **Consensus:** 3/3 verifiers

### MEDIUM: The `--agent-command` rerun line is wrong or unsafe, and untested
- **Location:** `lib/tryouts/cli/formatters/agent.rb:784`
- **Category:** command-echo-untested
- **Why it matters:** Paths aren't shell-quoted, and `relative_path` falls back to the file's basename when the file is outside the current directory. We confirmed that a file at `/tmp/.../dir with space/x_try.rb` produced `exe/try -vfs x_try.rb`. Line 562 also echoes the original ARGV without quoting. Lines 555-664 and 773-786 have no test coverage.
- **Suggested fix:** Use `Shellwords.escape` and the full path. Add tests, including one with a path that contains a space.
- **Consensus:** 3/3 verifiers

### MEDIUM: `handle_file_error` has never been exercised
- **Location:** `lib/tryouts/test_runner.rb:208`
- **Category:** dead-error-path
- **Why it matters:** This is the same NameError described above. No test exercises TestRunner's file-level error handling, and under `--parallel` the NameError is reported as the file's error.
- **Suggested fix:** Fix the signature. Add a test in which `FileProcessor#process` raises, and assert that the run returns 1 and reports the real message.
- **Consensus:** 2/3 verifiers

### MEDIUM: `--parallel` has only a smoke test
- **Location:** `lib/tryouts/test_runner.rb:139`
- **Category:** parallel-untested
- **Why it matters:** The only parallel test in CI runs two files that always pass. Nothing covers summed failure counts, rejected futures, or output attribution under threads. The `OUTPUT_CAPTURE_MONITOR` design serializes all test bodies across threads, and that is neither tested nor documented.
- **Suggested fix:** Add a `-j2` tryout with known failure counts and `#=1>` expectations. Use `future.value!`, and document that parallelism is per file only.
- **Consensus:** 3/3 verifiers

---

## Dead code

### HIGH: Stale debug line in `handle_file_error` raises NameError
- **Location:** `lib/tryouts/test_runner.rb:208`
- **Category:** stale-code
- **Why it matters:** The debug line was copied from an inline rescue, and `file`/`ex` are not in scope. We confirmed the NameError at runtime. Any exception that escapes FileProcessor never reaches `add_infrastructure_failure`. The `@status = :error` assignment on line 207 is never read.
- **Suggested fix:** Use the signature `handle_file_error(file, exception)`, and drop `@status = :error`.
- **Consensus:** 2/3 verifiers

### MEDIUM: The `## =>` parser branch is unreachable
- **Location:** `lib/tryouts/parsers/enhanced_parser.rb:256`
- **Category:** unreachable-branch
- **Why it matters:** We confirmed that `classify_comment_inhousely('## => 42', 5)` returns `:description`. The guard at line 283 is redundant as well.
- **Suggested fix:** Delete lines 256-257 and 283, or move the pattern above line 221 and add a tryout for it.
- **Consensus:** 3/3 verifiers

### MEDIUM: Per-line `ast:` payloads are computed but never read
- **Location:** `lib/tryouts/parsers/enhanced_parser.rb:140`
- **Category:** dead-computation
- **Why it matters:** The parser calls `Prism.parse` on every source line and every expectation, and nothing ever reads the resulting `[:ast]` field. The only purpose of `parse_ruby_line` and `parse_expectation` (in `shared_methods.rb`, lines 336-352) is to fill that field. This is O(lines) of extra parsing on top of the whole-file parse.
- **Suggested fix:** Remove the `ast:` keys and both helper methods.
- **Consensus:** 3/3 verifiers

### MEDIUM: SimpleCov group points at files that don't exist
- **Location:** `exe/try:21`
- **Category:** stale-config
- **Why it matters:** The group lists `testcase.rb` and `testbatch.rb`, but the files are `test_case.rb` and `test_batch.rb`, so the coverage report is misleading. The `respond_to?(:update_load_path)` guard at lines 38-39 is also vestigial.
- **Suggested fix:** Fix the paths, move `test_batch.rb` into the Execution group, and drop the guard.
- **Consensus:** 3/3 verifiers

### MEDIUM: `--enhanced-parser` offers a choice with only one option
- **Location:** `lib/tryouts/cli/opts.rb:165`
- **Category:** stale-feature-flag
- **Why it matters:** `PARSER_TYPES` contains only `:enhanced`, which is already the default. The flag, the validation branch and the duplicate "Parser Options:" separator are all dead, and `--help` still advertises the flag.
- **Suggested fix:** Delete the flag and the separator, and call `EnhancedParser.new` directly in `file_processor.rb`.
- **Consensus:** 3/3 verifiers

### MEDIUM: No caller passes `file_parsed`'s setup/teardown flags
- **Location:** `lib/tryouts/cli/formatters/verbose.rb:32`
- **Category:** dead-parameter
- **Why it matters:** In `-v` mode, VerboseFormatter prints an empty whitespace line for every file. CompactFormatter and AgentFormatter carry the same unused parameters.
- **Suggested fix:** Pass `setup_present`/`teardown_present` from FileProcessor, or remove the parameters and the empty line.
- **Consensus:** 3/3 verifiers

### LOW: `handle_batch_error` is never called
- **Location:** `lib/tryouts/test_batch.rb:742`
- **Category:** unused-method
- **Why it matters:** It is unreachable private code.
- **Suggested fix:** Delete it.
- **Consensus:** 3/3 verifiers

### LOW: `show_summary` is a no-op kept "for compatibility"
- **Location:** `lib/tryouts/test_batch.rb:693`
- **Category:** dead-code
- **Why it matters:** `finalize_results` computes an elapsed time only to pass it to this empty method. CLAUDE.md says to avoid backwards-compatibility code.
- **Suggested fix:** Delete `show_summary` and reduce `finalize_results` to `@status = :completed`.
- **Consensus:** 3/3 verifiers

### LOW: Unreachable fallback in `execute_with_fresh_context`
- **Location:** `lib/tryouts/test_batch.rb:283`
- **Category:** unreachable-branch
- **Why it matters:** On this path `@shared_context` is always a FreshContextFactory, so the `Object.new` fallback can never run. `containers_created_count` has no callers.
- **Suggested fix:** Call `@shared_context.create_container` unconditionally, and delete the counter.
- **Consensus:** 3/3 verifiers

### LOW: Pre-v3 class-level API remnants
- **Location:** `lib/tryouts.rb:85`
- **Category:** unused-method
- **Why it matters:** `test_stopping_error?`, `@container`, `@cases` and `@testcase_io`, and the `noisy`/`fails`/etc. accessors are unused. The only reference is a tryout that asserts they exist.
- **Suggested fix:** Remove them and update `try/core/class_functionality_try.rb`.
- **Consensus:** 3/3 verifiers

### LOW: Dead code in AgentFormatter
- **Location:** `lib/tryouts/cli/formatters/agent.rb:714`
- **Category:** unused-method
- **Why it matters:** `get_test_discovery_patterns` is never called, the `details` local (lines 291-293) is never read, `private` is declared twice, and the `:context_info` and `:warnings` keys are written but never read.
- **Suggested fix:** Delete all of them.
- **Consensus:** 3/3 verifiers

### LOW: `private` has no effect on `def self.` methods
- **Location:** `lib/tryouts/cli/line_spec_parser.rb:40`
- **Category:** stale-code
- **Why it matters:** `parse_line_spec` and `matches?` are still public, which misleads readers.
- **Suggested fix:** Remove the keyword, or use `private_class_method :parse_line_spec`.
- **Consensus:** 3/3 verifiers

---

## Dependency risk

### LOW: minitest and rspec are hard runtime dependencies
- **Location:** `tryouts.gemspec:25` (also line 27)
- **Category:** dependency-risk
- **Why it matters:** Both are required only lazily, for the optional translator modes, yet every install pulls in both frameworks. The `rspec >= 3.0, < 5.0` range will also accept rspec 4.0 final even though the code was only exercised against a git beta. This can conflict with host apps that pin other versions. The TTY comment on line 24 sits above the wrong entries.
- **Suggested fix:** Drop both from `add_dependency`, and rescue `LoadError` with a clear message. If they stay, narrow rspec to the tested range (e.g. `~> 3.13`) and fix the comment.
- **Consensus:** 3/3 verifiers
