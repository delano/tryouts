# lib/tryouts/cli/formatters/token_budget.rb

class Tryouts
  class CLI
    # Token budget tracking for agent-optimized output
    class TokenBudget
      DEFAULT_LIMIT = 5000
      BUFFER_PERCENT = 0.05  # 5% buffer to avoid going over

      attr_reader :limit, :used, :remaining

      def initialize(limit = DEFAULT_LIMIT)
        @limit = limit
        @used = 0
        @buffer_size = (@limit * BUFFER_PERCENT).to_i
      end

      # Estimate tokens in text (rough approximation: 1 token ≈ 4 characters)
      def estimate_tokens(text)
        return 0 if text.nil? || text.empty?

        (text.length / 4.0).ceil
      end

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

      # Get utilization percentage
      def utilization
        (@used.to_f / @limit * 100).round(1)
      end

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

      # Distribution strategy for budget allocation
      def allocate_budget
        {
          summary: (@limit * 0.20).to_i,      # 20% for file summaries
          failures: (@limit * 0.60).to_i,     # 60% for failure details
          context: (@limit * 0.15).to_i,      # 15% for additional context
          buffer: (@limit * 0.05).to_i        # 5% buffer
        }
      end

      # Reset budget
      def reset
        @used = 0
      end

      def to_s
        "TokenBudget[#{@used}/#{@limit} tokens (#{utilization}%)]"
      end
    end
  end
end
