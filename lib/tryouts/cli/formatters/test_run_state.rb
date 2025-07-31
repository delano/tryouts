# lib/tryouts/cli/formatters/test_run_state.rb

class Tryouts
  class CLI
    # Immutable state tracking for test runs using modern Ruby Data.define
    class TestRunState < Data.define(
      :total_tests,
      :passed,
      :failed,
      :errors,
      :files_completed,
      :total_files,
      :current_file,
      :current_test,
      :start_time
    )
      def self.empty
        new(
          total_tests: 0,
          passed: 0,
          failed: 0,
          errors: 0,
          files_completed: 0,
          total_files: 0,
          current_file: nil,
          current_test: nil,
          start_time: nil
        )
      end

      def self.initial(total_files: 0)
        empty.with(
          total_files: total_files,
          start_time: Time.now
        )
      end

      # Update state based on formatter events using pattern matching
      def update_from_event(event_type, *args, **kwargs)
        case event_type
        in :phase_header
          _, file_count, level = args
          if level == 0 && file_count
            with(total_files: file_count, start_time: Time.now)
          else
            self
          end

        in :file_start
          file_path = args[0]
          pretty_path = Console.pretty_path(file_path)
          with(current_file: pretty_path)

        in :file_end
          with(
            files_completed: files_completed + 1,
            current_file: nil
          )

        in :test_start
          test_case = args[0]
          desc = test_case.description.to_s
          desc = "test #{args[1]}" if desc.empty?
          with(current_test: desc)

        in :test_end
          with(current_test: nil)

        in :test_result
          result_packet = args[0]
          updated_state = with(total_tests: total_tests + 1)

          case result_packet.status
          when :passed
            updated_state.with(passed: passed + 1)
          when :failed
            updated_state.with(failed: failed + 1)
          when :error
            updated_state.with(errors: errors + 1)
          else
            updated_state
          end

        else
          # Unknown event, return unchanged state
          self
        end
      end

      # Computed properties
      def elapsed_time
        start_time ? Time.now - start_time : 0
      end

      def issues_count
        failed + errors
      end

      def passed_count
        total_tests - issues_count
      end

      def has_issues?
        issues_count > 0
      end

      def tests_run?
        total_tests > 0
      end

      def files_remaining
        total_files - files_completed
      end

      def completion_percentage
        return 0 if total_files == 0
        (files_completed.to_f / total_files * 100).round(1)
      end
    end
  end
end
