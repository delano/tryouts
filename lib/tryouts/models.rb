class Tryouts
  # Base class for Setup and Teardown
  class PrePostAction
    attr_reader :code

    def initialize(code)
      @code = code&.join("\n")
    end

    def empty?
      code.nil? || code.strip.empty?
    end
  end

  class Setup < PrePostAction
  end

  class Teardown < PrePostAction
  end

  class TestCase
    attr_reader :description, :code, :expectations

    def initialize(description: nil, code: nil, expectations: nil)
      @description = description&.join("\n")
      @code = code&.join("\n")
      @expectations = expectations
    end

    def empty?
      code.nil? || code.strip.empty?
    end
  end

  class Testrun
    attr_reader :setup, :test_cases, :teardown

    def initialize(setup: nil, test_cases: [], teardown: nil)
      @setup = setup
      @test_cases = test_cases
      @teardown = teardown
    end

    def empty?
      test_cases.empty? &&
        (setup.nil? || setup.empty?) &&
        (teardown.nil? || teardown.empty?)
    end
  end
end
