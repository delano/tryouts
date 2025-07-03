# lib/tryouts/safe_execution_environment.rb

require_relative 'safety_config'

class Tryouts
  class SafeExecutionEnvironment
    attr_reader :captured_stdout, :captured_stderr, :exit_code

    def initialize
      @original_globals = {}
      @original_constants = {}
      @original_load_path = nil
      @captured_stdout = ""
      @captured_stderr = ""
      @exit_code = nil
    end

    # Execute code with comprehensive protection
    def execute_safely(file, &block)
      if SafetyConfig.can_fork?
        execute_in_fork(file, &block)
      else
        execute_in_process(file, &block)
      end
    end

    private

    def execute_in_fork(file, &block)
      reader, writer = IO.pipe

      pid = fork do
        reader.close

        begin
          setup_isolated_environment
          result = capture_output(&block)

          Marshal.dump(result, writer)
          writer.close
          exit 0

        rescue SystemExit => e, SystemExit
          result = {
            success: false,
            error: "Test code called exit(#{e.status})",
            exit_code: e.status,
            stdout: @captured_stdout,
            stderr: @captured_stderr
          }
          Marshal.dump(result, writer)
          writer.close
          exit e.status

        rescue Exception => e, SystemExit
          result = {
            success: false,
            error: "#{e.class}: #{e.message}",
            backtrace: e.backtrace,
            stdout: @captured_stdout,
            stderr: @captured_stderr
          }
          Marshal.dump(result, writer)
          writer.close
          exit 1
        end
      end

      writer.close

      begin
        # Timeout protection
        timeout = SafetyConfig.settings[:timeout_seconds]
        result_data = nil

        if timeout > 0
          require 'timeout'
          Timeout.timeout(timeout) do
            result_data = reader.read
          end
        else
          result_data = reader.read
        end

        reader.close
        Process.wait(pid)
        child_status = $?

        if result_data.empty?
          return {
            success: false,
            error: "Child process failed to return data",
            exit_code: child_status.exitstatus
          }
        end

        result = Marshal.load(result_data)
        result[:exit_code] = child_status.exitstatus
        result

      rescue Timeout::Error, SystemExit
        Process.kill('KILL', pid) if pid
        Process.wait(pid) if pid
        {
          success: false,
          error: "Test execution timed out after #{timeout} seconds",
          exit_code: -1
        }
      rescue => e
        Process.kill('KILL', pid) if pid
        Process.wait(pid) if pid
        {
          success: false,
          error: "Fork execution failed: #{e.message}",
          exit_code: -1
        }
      ensure
        reader.close unless reader.closed?
      end
    end

    def execute_in_process(file, &block)
      begin
        save_global_state if SafetyConfig.settings[:protect_globals]
        setup_exit_protection if SafetyConfig.settings[:exit_protection]

        if SafetyConfig.settings[:capture_output]
          capture_output(&block)
        else
          { success: true, result: block.call }
        end

      rescue SystemExit => e
        {
          success: false,
          error: "Test code called exit(#{e.status})",
          exit_code: e.status,
          stdout: @captured_stdout,
          stderr: @captured_stderr
        }
      rescue Exception => e
        {
          success: false,
          error: "#{e.class}: #{e.message}",
          backtrace: e.backtrace,
          stdout: @captured_stdout,
          stderr: @captured_stderr
        }
      ensure
        restore_global_state if SafetyConfig.settings[:protect_globals]
      end
    end

    def save_global_state
      @original_globals = {
        load_path: $LOAD_PATH.dup,
        program_name: $PROGRAM_NAME.dup,
        verbose: $VERBOSE,
        debug: $DEBUG
      }

      @original_env = ENV.to_h.dup

      if SafetyConfig.settings[:signal_protection]
        @original_signals = {}
        %w[INT TERM HUP USR1 USR2].each do |sig|
          begin
            @original_signals[sig] = Signal.trap(sig, 'DEFAULT')
          rescue ArgumentError
            # Signal not available on this platform
          end
        end
      end
    end

    def restore_global_state
      $LOAD_PATH.replace(@original_globals[:load_path]) if @original_globals[:load_path]
      $PROGRAM_NAME = @original_globals[:program_name] if @original_globals[:program_name]
      $VERBOSE = @original_globals[:verbose]
      $DEBUG = @original_globals[:debug]

      # Restore critical environment variables
      %w[PATH GEM_PATH GEM_HOME BUNDLE_GEMFILE].each do |key|
        ENV[key] = @original_env[key] if @original_env[key]
      end

      if @original_signals
        @original_signals.each do |sig, handler|
          begin
            Signal.trap(sig, handler)
          rescue ArgumentError
          end
        end
      end

      GC.start
    end

    def setup_isolated_environment
      $VERBOSE = nil
      $DEBUG = false

      if SafetyConfig.settings[:signal_protection]
        %w[INT TERM HUP].each do |sig|
          begin
            Signal.trap(sig, 'DEFAULT')
          rescue ArgumentError
          end
        end
      end
    end

    def setup_exit_protection
      original_exit = method(:exit)
      original_abort = method(:abort)

      define_singleton_method(:exit) do |code = 0|
        raise SystemExit.new(code)
      end

      define_singleton_method(:abort) do |msg = nil|
        $stderr.puts msg if msg
        raise SystemExit.new(1)
      end

      @original_exit = original_exit
      @original_abort = original_abort
    end

    def capture_output(&block)
      original_stdout = $stdout
      original_stderr = $stderr

      stdout_capture = StringIO.new
      stderr_capture = StringIO.new

      $stdout = stdout_capture
      $stderr = stderr_capture

      begin
        result = block.call
        @captured_stdout = stdout_capture.string
        @captured_stderr = stderr_capture.string

        {
          success: true,
          result: result,
          stdout: @captured_stdout,
          stderr: @captured_stderr
        }
      ensure
        $stdout = original_stdout
        $stderr = original_stderr
      end
    end
  end
end
