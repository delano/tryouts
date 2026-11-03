# lib/tryouts/script_binding.rb
#
# frozen_string_literal: true

class Tryouts
  # Bindings that evaluate code the way `ruby file.rb` evaluates a script.
  #
  # Each binding has a fresh object as self that prints as "main" (one per
  # file in shared context, one per test in fresh context, so instance
  # variables never cross over), no local variables, and the top-level
  # scope: `class Foo` defines ::Foo, `class String` reopens ::String,
  # `Module.nesting` is [] and `__method__` is nil. Top-level `include`
  # mixes into Object, and `private def helper` works, as in a script.
  #
  # Constants are global, as in a script. Constants a file defines on Object
  # (found by Object.const_source_location pointing at the file) are removed
  # with #remove_constants when the file finishes, and in fresh context after
  # each test, so the next run of the setup defines them afresh and another
  # file may reuse the name. Constants defined by required libraries are
  # never removed. Under --parallel, files that run at the same time still
  # share Object's constants while they run, so they should not define the
  # same top-level constant.
  #
  # Differences from a script:
  # - A top-level `def` defines a public singleton method on self rather than
  #   a private method on Object. It is callable from the file's top-level
  #   code and blocks there, but not from inside a class the file defines,
  #   and it never shadows a Kernel method for any other code.
  # - Top-level `using` raises. Every section and expectation is evaluated
  #   separately, so a refinement activated at the top level could not reach
  #   the code after it. `using` inside a class or module body works.
  module ScriptBinding
    # The private methods of a script's main object, and its name.
    module Main
      def to_s
        'main'
      end
      alias inspect to_s

      private

      def include(*modules)
        Object.include(*modules)
      end

      def public(*names)
        singleton_class.send(:public, *names)
      end

      def private(*names)
        singleton_class.send(:private, *names)
      end

      def define_method(...)
        define_singleton_method(...)
      end

      def using(_refinement)
        raise 'top-level `using` is not supported in a tryouts file; activate the refinement inside a class or module body'
      end
    end

    # @return [Binding] a binding whose self is a new main-like object
    def self.create
      Object.new.extend(Main).instance_eval(&TOPLEVEL_BLOCK)
    end

    # Removes the constants on Object that were defined by code in path.
    # @param path [String] the file the code was evaluated as
    def self.remove_constants(path)
      Object.constants.each do |name|
        Object.send(:remove_const, name) if Object.const_source_location(name)&.first == path
      end
    end
  end
end

# A block written at the top level of this file: no local variables in scope
# and the top-level lexical scope. instance_eval runs it with a new self, and
# the binding it returns keeps that scope.
Tryouts::ScriptBinding.const_set(:TOPLEVEL_BLOCK, proc { binding })
Tryouts::ScriptBinding.private_constant(:TOPLEVEL_BLOCK)
