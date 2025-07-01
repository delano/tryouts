# test/test_generator.rb
module TestGenerator
  def self.generate_tests(subject_class, &block)
    test_spec = TestSpec.new(subject_class)
    test_spec.instance_eval(&block)
    test_spec.generate_rspec_tests
  end

  class TestSpec
    def initialize(subject_class)
      @subject_class = subject_class
      @test_cases = []
      @setup_data = {}
    end

    def setup(**data)
      @setup_data = data
      self
    end

    def should_return(expected, method:, args: [], description: nil)
      @test_cases << {
        type: :return,
        method: method,
        args: args,
        expected: expected,
        description: description || "#{method}(#{args.join(', ')}) returns #{expected}",
        setup: @setup_data.dup
      }
    end

    def should_raise(exception_class, method:, args: [], description: nil)
      @test_cases << {
        type: :raise,
        method: method,
        args: args,
        expected: exception_class,
        description: description || "#{method}(#{args.join(', ')}) raises #{exception_class}",
        setup: @setup_data.dup
      }
    end

    def should_change(attribute, method:, args: [], from:, to:, description: nil)
      @test_cases << {
        type: :change,
        method: method,
        args: args,
        attribute: attribute,
        from: from,
        to: to,
        description: description || "#{method} changes #{attribute} from #{from} to #{to}",
        setup: @setup_data.dup
      }
    end

    def context_group(description, **group_setup, &block)
      old_setup = @setup_data
      @setup_data = @setup_data.merge(group_setup)

      @test_cases << {
        type: :context,
        description: description,
        setup: @setup_data.dup,
        tests: []
      }

      context_tests = []
      old_cases = @test_cases
      @test_cases = context_tests

      instance_eval(&block)

      old_cases.last[:tests] = context_tests
      @test_cases = old_cases
      @setup_data = old_setup
    end

    def generate_rspec_tests
      test_cases = @test_cases
      subject_class = @subject_class

      RSpec.describe subject_class do
        let(:subject_instance) { subject_class.new }

        define_method :setup_instance do |setup_data|
          setup_data.each { |attr, value| subject_instance.instance_variable_set("@#{attr}", value) }
          subject_instance
        end

        # Generate tests using a method that captures the test_cases
        define_method :generate_test_cases do |cases, rspec_context|
          cases.each do |test_case|
            case test_case[:type]
            when :context
              rspec_context.context test_case[:description] do
                generate_test_cases(test_case[:tests], self)
              end
            when :return
              rspec_context.it test_case[:description] do
                instance = setup_instance(test_case[:setup])
                result = instance.public_send(test_case[:method], *test_case[:args])
                expect(result).to eq(test_case[:expected])
              end
            when :raise
              rspec_context.it test_case[:description] do
                instance = setup_instance(test_case[:setup])
                expect {
                  instance.public_send(test_case[:method], *test_case[:args])
                }.to raise_error(test_case[:expected])
              end
            when :change
              rspec_context.it test_case[:description] do
                instance = setup_instance(test_case[:setup])
                expect {
                  instance.public_send(test_case[:method], *test_case[:args])
                }.to change { instance.public_send(test_case[:attribute]) }
                  .from(test_case[:from]).to(test_case[:to])
              end
            end
          end
        end

        generate_test_cases(test_cases, self)
      end
    end
  end
end

# Test class
class Calculator
  attr_accessor :memory

  def initialize
    @memory = 0
  end

  def add(a, b)
    a + b
  end

  def divide(a, b)
    raise ZeroDivisionError if b == 0
    a / b
  end

  def store(value)
    old_memory = @memory
    @memory = value
    old_memory
  end
end

# Generate tests
TestGenerator.generate_tests(Calculator) do
  should_return 5, method: :add, args: [2, 3]
  should_return 10, method: :add, args: [4, 6]

  should_raise ZeroDivisionError, method: :divide, args: [1, 0]
  should_return 2, method: :divide, args: [6, 3]

  context_group 'with memory operations', memory: 10 do
    should_change :memory, method: :store, args: [25], from: 10, to: 25
    should_return 10, method: :store, args: [15], description: 'returns previous memory value'
  end
end
