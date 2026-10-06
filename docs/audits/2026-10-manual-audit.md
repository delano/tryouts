# Tryouts 4.0.0.pre1 audit

Branch `agent/hopeful-wright-dpum84` at 511f2e4. Ruby 3.3.6. Every finding below was verified by running the CLI against a fixture or by reading the surrounding code; the reproduction fixtures were not committed.

Baseline: `try/core try/expectations try/formatters try/translators` pass (all green). Rubocop is not run in CI and reports 340 offenses (252 auto-correctable, mostly Layout/ExtraSpacing and Style/StringLiterals).

## Critical: results that lie

1. **`--parallel` corrupts agent-mode results.** `lib/tryouts/cli/formatters/agent.rb:73-91` keeps one unsynchronized `@current_file_data` for all files. Concurrent `file_start` calls overwrite it. Four files with two failing tests each under `-j 4` print `SUMMARY: 7 testcases passed, 1 failed` (sequential: `0 passed, 8 failed`). Same unsynchronized read-modify-write in `live_status_manager.rb:58` and `test_result_aggregator.rb:38-41` (the "thread-safe" comment is not backed by a lock).

2. **`--rspec` always exits 0.** `lib/tryouts/test_executor.rb:84-89` discards `RSpec::Core::Runner.run`'s return value. `1 #=> 2` exits 0 under `--rspec`, 1 under direct and `--minitest`. `RSpec.world` is also never reset between files, so file N re-runs every earlier file's groups.

3. **Translators drop every expectation type except `#=>` and `#=!>`.** `rspec_translator.rb:93,160` and `minitest_translator.rb:284,357` generate empty example bodies for `#==>`, `#=/=>`, `#=|>`, `#=:>`, `#=~>`, `#=%>`, `#=*>`, `#=1>`, `#=<>`. Those tests pass unconditionally under either framework. Class-form `#=!> ArgumentError` compiles to `expect(ArgumentError).to be_truthy` / `assert ArgumentError`, which can never fail.

4. **`--generate-minitest` emits invalid Ruby.** `minitest_translator.rb:347,358` interpolate the `Expectation` Data object instead of `expectation.content`: `assert_equal #<data Tryouts::Expectation content="2", type=:regular>, result`. Every generated test method is a syntax error. `--minitest` on `try/expectations/` also aborts with "0 tests passed" because orphan blocks are `class_eval`'d (`minitest_translator.rb:258`) and lose local variables.

5. **`result` / `_` go stale when the test value is `nil` or `false`.** `expectation_evaluators/base.rb:72` guards the singleton redefinition with `elsif expectation_result.actual_result`, so a falsy result keeps the previous test's value. In shared context, `42 #=> 42` followed by `nil #==> result == 42` passes.

6. **`--agent-focus critical` exits 0 on plain failures.** `test_runner.rb:48-52` returns errors + infrastructure failures only. A file with two failed expectations and no errors exits 0. CI's `agent-output` job runs this focus on `try/core` and `try/expectations`, so that job cannot fail on a wrong expectation.

## High: wrong counts, wrong exit codes, silent loss

7. **Exit code inflates with multiple setup failures.** `test_executor.rb:75-79` returns the global `infrastructure_failure_count` for any file where no tests ran, so file N contributes N. Three files that raise in setup exit 6. README's "exit code = number of failing tests" is wrong here, and anything above 255 wraps.

8. **Timeout does not cover exception tests.** `test_batch.rb:305-315` evaluates the code for a `#=!>` test outside `execute_with_timeout`; only the expectation evaluation (317) is guarded. With `test_timeout: 1`, `sleep 3` + `#=!> RuntimeError` takes 4s. Neither `test_timeout` nor `max_consecutive_failures` is passed from `TestExecutor` (34-42) or exposed in `opts.rb`, so the 30s and 10-failure defaults are the only values reachable from the CLI.

9. **`-j` swallows the next positional argument.** `opts.rb:127-130` declares `--parallel [THREADS]`, so `try -j some_try.rb` consumes the path as THREADS (`to_i` → 0, discarded), leaves the file list empty, and auto-discovers the whole suite.

10. **Fresh-context teardown cannot see setup state.** `test_batch.rb:642` evals teardown against `@container`, but fresh-mode setup populates `@setup_container` (589). `@x = 42` in setup, `puts @x` in teardown prints `nil` under `--no-shared-context`.

11. **Multi-line descriptions lose their first line.** `shared_methods.rb:12-38` breaks on the next `:description` token before it finds code, so `## First line` / `## Second line` yields a test described only as "Second line". The continuation branch at 49-51 is unreachable for the common case.

12. **Agent mode swallows fatal errors.** `agent.rb:195-201` buffers `error` calls and renders only in `grand_total`; `try --agent missing_try.rb` prints nothing and exits 1. When it does render, setup errors and circuit-breaker notices appear under the heading `Syntax Errors:`.

13. **Setup failure reported as green.** `compact.rb:96-118` and `verbose.rb:97-116` print `✓ 0 passed` after a setup failure. In agent mode the broken file is dropped from `files_under_test` because `TestBatch#run` returns before `file_end` (`test_batch.rb:94-99`).

14. **`#=*>` passes when an exception was raised.** `non_nil.rb:56-64` has a dead `caught_exception:` branch; the evaluator receives the exception object as the result and `!nil?` is true, contradicting its own doc comment.

15. **`handle_file_error` raises NameError.** `test_runner.rb:208` interpolates undefined `file` and `ex`. Latent because `FileProcessor#process` rescues nearly everything, but any error that reaches `process_file`'s rescue crashes the runner.

## Medium

16. `#=<>` only inverts `==` (`intentional_failure.rb`). `"123" #=<> /\d+/` passes, as does README's `#=<> result.include?(4)` regardless of contents.
17. `#=%> result * 2` (documented in `performance_time.rb:21` and `try/expectations/comprehensive_expectations_try.rb`) is a tautology: `result` is the measured time.
18. `exception.rb:57` checks `is_a?(Class)`, so `#=!> Comparable` (any Module) always passes.
19. Descriptions containing `'` produce unparsable generated code in both translators (`rspec_translator.rb:136`); no escaping.
20. `minitest_translator.rb:272,340` uses `assert_raises(StandardError)` while the direct runner also catches `SystemStackError`, `NoMemoryError`, `SecurityError`, `ScriptError` (`test_batch.rb:309`).
21. In exception tests every non-`#=!>` evaluator receives the exception as `actual_result` (`test_batch.rb:318`); mixed expectations there are effectively unsupported and undocumented.
22. `-q` on a single file prints `.FE` with no newline and no summary (`test_runner.rb:43`, `quiet.rb:47-50`).
23. `--agent-limit` meters only failure sections; SUMMARY/CONTEXT/warnings are never charged (`agent.rb:404-435`), contradicting the help text.
24. Agent summary prints elapsed time twice on failing runs and a bare `(6ms)` line on passing runs (`agent.rb:277-304`; `0` is truthy).
25. Compact formatter splits output across stdout and stderr (`compact.rb:20-29,218-236`); `2>/dev/null` loses totals, `>/dev/null` loses tests. `verbose.rb:226-231` uses `Kernel#printf`, bypassing `@stdout`.
26. `Console.bgcolor` (`console.rb:111`) indexes `ATTRIBUTES` instead of `BGCOLOURS`, so every background colour resets to default. Currently unused.
27. `TestBatch#finalize_results` sets `@status = :completed` after the setup-failure and orphan-failure paths already set `:failed` (`test_batch.rb:96-97,167-169`), so `completed?` is true for aborted batches.
28. `context.define_singleton_method(:error)` (`test_batch.rb:410`) persists on the shared container, so a later non-exception test can read a stale `error`.
29. `parse_ruby_line` runs a separate `Prism.parse` on every code line and expectation, and the resulting `ast:` key is never read anywhere. Parsing the 54-file suite takes 124ms with it, 74ms without.
30. `cli.rb:67` keys line specs by path, so `file:10 file:20` keeps only the last spec.

## Low, dead code, docs

- Parsed but unused options: `-c/--compact`, `--enhanced-parser`, `options[:format]` (`factory.rb:23`). `agent.rb:707` reads `@options[:line_spec]`, which is never set on formatter options.
- `--help` prints the "Parser Options:" separator twice (`opts.rb:132,164`). `opts.rb:279` rescues only `InvalidOption`, so `--agent-limit abc` falls through to the generic handler.
- CLAUDE.md documents `--fresh-context`, which does not exist. README's `#=*> result` argument is decorative; the parser discards it.
- `TestBatch` builds a `CompactFormatter` it never uses (`test_batch.rb:45`). `handle_batch_error`, `show_summary`, and the "backwards compatibility" fallback in `execute_with_fresh_context` are dead. `exception.rb:26-46` re-executes test code in a branch the comment says cannot be reached.
- Never invoked: `FormatterInterface#with_indent`, `#update_live_status`, `LiveStatusManager#write_output`, `NoOpStatusDisplay`, `TestRunState.initial` and its helpers, `TokenBudget#allocate_budget/#reset/#utilization`, `AgentFormatter#get_test_discovery_patterns`, `Tryouts.cases/container/testcase_io/noisy/fails` (`tryouts.rb:16-25`).
- `classify_comment_inhousely` branch for `## =>` (`enhanced_parser.rb:256`) is unreachable; `^##` matches first at 221.
- Summary/issue-count block is copy-pasted across `quiet.rb`, `compact.rb`, `verbose.rb`, `agent.rb` (twice); `format_timing` exists three times.
- TTY: `STATUS_LINES` is 4 in `tty_detector.rb:9` and 5 in `tty_status_display.rb:14`; `get_cursor_position` returns a hard-coded `[10,0]`; `register_cleanup_handlers` clobbers existing INT/TERM/QUIT/HUP handlers.
- `tryouts.gemspec` declares `irb` as a runtime dependency; nothing under `lib/` or `exe/` requires it. `minitest` and `rspec` are also runtime deps, pulled in for every consumer.
- Comments in `test_batch.rb:26`, `enhanced_parser.rb:58` etc. say "Ruby 3.4+" while the gemspec requires 3.2.
- `try/demo_live_try.rb` fails by design (1 real failure) and sits in the auto-discovery path, so a bare `bundle exec try` from the repo root is red.

## Recommended order

1. Fix the four "results lie" items that affect CI first: `--rspec` exit code (#2), critical-focus exit code (#6), parallel agent race (#1), stale `result` (#5).
2. Either finish the translators (#3, #4, #19, #20) or mark `--rspec`/`--minitest` experimental and drop them from the README feature list. Right now they pass tests the direct runner fails.
3. Exit-code and reporting fixes: #7, #12, #13, #22, #24.
4. Parser: #11, #29.
5. Delete the dead code and unused options; run `rubocop -A` for the 252 safe corrections and add rubocop to CI.
