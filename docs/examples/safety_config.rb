# docs/examples/safety_config.rb
#
# frozen_string_literal: true
#
# NOTE: This is an example/template file for demonstration purposes.
# This functionality is not currently implemented in the main codebase.

class Tryouts
  module SafetyConfig
    class << self
      # Default safety settings
      DEFAULT_SETTINGS = {
        fork_isolation: true,        # Use process forking for isolation
        capture_output: true,        # Capture stdout/stderr
        protect_globals: true,       # Save/restore global state
        exit_protection: true,       # Prevent exit() calls
        signal_protection: true,     # Protect signal handlers
        timeout_seconds: 30,         # Max execution time per file
        memory_limit_mb: 256,        # Memory limit for child processes
        temp_dir: '/tmp',           # Directory for temporary files
        verbose_failures: false,      # Show detailed failure info
      }.freeze

      def settings
        @settings ||= DEFAULT_SETTINGS.dup
      end

      def configure
        yield(settings) if block_given?
      end

      # Environment-based overrides
      def apply_environment_overrides!
        settings[:fork_isolation]   = false if ENV['TRYOUTS_NO_FORK']
        settings[:capture_output]   = false if ENV['TRYOUTS_NO_CAPTURE']
        settings[:timeout_seconds]  = ENV['TRYOUTS_TIMEOUT'].to_i if ENV['TRYOUTS_TIMEOUT']
        settings[:verbose_failures] = true if ENV['TRYOUTS_VERBOSE']
        settings[:temp_dir]         = ENV['TRYOUTS_TEMP_DIR'] if ENV['TRYOUTS_TEMP_DIR']
      end

      # Platform detection
      def can_fork?
        return false if settings[:fork_isolation] == false
        return false if RUBY_PLATFORM == 'java'
        return false if RUBY_PLATFORM =~ /mswin|mingw/
        return false if ENV['TRYOUTS_NO_FORK']

        true
      end

      def development_mode?
        ENV['TRYOUTS_ENV'] == 'development' ||
          ENV['RUBY_ENV'] == 'development' ||
          $DEBUG
      end

      # Safety level presets
      def paranoid!
        settings.merge!(
          fork_isolation: true,
          capture_output: true,
          protect_globals: true,
          exit_protection: true,
          signal_protection: true,
          timeout_seconds: 10,
          memory_limit_mb: 128,
        )
      end

      def relaxed!
        settings.merge!(
          fork_isolation: false,
          capture_output: true,
          protect_globals: true,
          exit_protection: true,
          signal_protection: false,
          timeout_seconds: 60,
          memory_limit_mb: 512,
        )
      end

      def development!
        settings.merge!(
          fork_isolation: false,
          capture_output: false,
          protect_globals: false,
          exit_protection: false,
          signal_protection: false,
          timeout_seconds: 300,
          verbose_failures: true,
        )
      end
    end
  end
end

# Auto-apply environment overrides
Tryouts::SafetyConfig.apply_environment_overrides!
