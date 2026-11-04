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
  # Constants are global, as in a script. The classes and constants a file
  # defines stay defined for the rest of the run, the way they would if
  # several Ruby files were loaded into one process (RSpec and Minitest
  # behave the same), so two files should not define the same top-level
  # class differently. Under --parallel, files that run at the same time
  # share them too.
  #
  # Fresh context re-runs the setup (and interludes) for every test. Before
  # it does so for the second and later tests, #remove_constants removes the
  # constants defined directly on Object by the file, so `class Point <
  # Struct.new(:x, :y)` is defined afresh rather than raising superclass
  # mismatch. Nothing is removed after the last test, so its values still
  # inspect correctly in the summary. Consequences of re-running class
  # definitions:
  # - Constants the file nests inside an existing namespace (JSON::Point,
  #   or a constant inside a module of a library) are not removed.
  # - Each re-run defines new class objects, so inherited hooks and
  #   registries kept by retained library classes see every re-run.
  #
  # Differences from a script:
  # - A top-level `def` defines a public singleton method on self rather than
  #   a private method on Object. It is callable from the file's top-level
  #   code and blocks there, but not from inside a class the file defines,
  #   and it never shadows a Kernel method for any other code. A bare
  #   `private` makes the top-level defs after it private, and a bare
  #   `public` ends that, as in a script.
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

      # A bare `public` or `private` sets the visibility of the top-level
      # defs after it, as in a script.
      def public(*names)
        return singleton_class.send(:public, *names) unless names.empty?

        singleton_class.instance_variable_set(:@private_defs, false)
        nil
      end

      def private(*names)
        return singleton_class.send(:private, *names) unless names.empty?

        singleton_class.instance_variable_set(:@private_defs, true)
        nil
      end

      def singleton_method_added(name)
        singleton_class.send(:private, name) if singleton_class.instance_variable_get(:@private_defs)
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

    # Removes the constants defined directly on Object (not those it
    # inherits from an included module) by code in path.
    # @param path [String] the file the code was evaluated as
    def self.remove_constants(path)
      Object.constants(false).each do |name|
        Object.send(:remove_const, name) if Object.const_source_location(name, false)&.first == path
      end
    end
  end
end

# A block written at the top level of this file: no local variables in scope
# and the top-level lexical scope. instance_eval runs it with a new self, and
# the binding it returns keeps that scope.
Tryouts::ScriptBinding.const_set(:TOPLEVEL_BLOCK, proc { binding })
Tryouts::ScriptBinding.private_constant(:TOPLEVEL_BLOCK)
