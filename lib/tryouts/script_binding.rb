# lib/tryouts/script_binding.rb
#
# frozen_string_literal: true

class Tryouts
  # Bindings that evaluate code the way `ruby file.rb` evaluates a script.
  #
  # Each binding has a fresh Object as self (one per file in shared context,
  # one per test in fresh context, so instance variables never cross over),
  # no local variables, and the top-level scope: `class Foo` defines ::Foo,
  # `class String` reopens ::String, `Module.nesting` is [] and `def` defines
  # a method on Object. Like a script's, those definitions are global: two
  # files that define the same class share it.
  #
  # Two differences from a script remain:
  # - A top-level `def` is a public Object method, where a script makes it
  #   private. The binding is taken inside a method, and `def` in a method
  #   body has public visibility.
  # - Top-level `using` raises. Every section and expectation is evaluated
  #   separately, so a refinement activated at the top level could not reach
  #   the code after it. `using` inside a class or module body works.
  module ScriptBinding
    # `include` and `using` are private methods of main, the top-level self.
    # A script's self here is a plain Object, so it gets equivalents.
    module TopLevel
      private

      def include(*modules)
        Object.include(*modules)
      end

      def using(_refinement)
        raise 'top-level `using` is not supported in a tryouts file; activate the refinement inside a class or module body'
      end
    end

    # Defined at the top level so the binding it returns has the top-level
    # cref, then removed from Object so no object carries it. The
    # UnboundMethod keeps working after removal.
    TOPLEVEL_BINDING.eval('def __tryouts_binding__ = binding', __FILE__, __LINE__)
    BINDING_METHOD = Object.instance_method(:__tryouts_binding__)
    Object.send(:remove_method, :__tryouts_binding__)

    REDEFINITION_WARNING = /already initialized constant|previous definition of/

    # Fresh context re-runs the setup and interludes before every test, so
    # their constants are assigned again. Those warnings are noise on a re-run
    # only; QuietRedefinition drops them while #quiet_redefinitions runs. The
    # flag is thread-local, so a file running under --parallel never silences
    # another file's warnings.
    module QuietRedefinition
      def warn(message, ...)
        return if Thread.current[:tryouts_quiet_redefinitions] && message.match?(REDEFINITION_WARNING)

        super
      end
    end
    Warning.singleton_class.prepend(QuietRedefinition)

    # @return [Binding] a binding whose self is a new Object
    def self.create
      BINDING_METHOD.bind_call(Object.new.extend(TopLevel))
    end

    def self.quiet_redefinitions
      previous                                     = Thread.current[:tryouts_quiet_redefinitions]
      Thread.current[:tryouts_quiet_redefinitions] = true
      yield
    ensure
      Thread.current[:tryouts_quiet_redefinitions] = previous
    end
  end
end
