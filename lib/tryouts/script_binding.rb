# lib/tryouts/script_binding.rb
#
# frozen_string_literal: true

class Tryouts
  # A Binding whose self is the given object and which has no local
  # variables.
  #
  # `object.instance_eval('binding')` looks equivalent but captures the local
  # variables of the method that calls it, so every local in the executor
  # (e.g. `container`) would be visible to, and clobberable by, test code.
  # A binding taken inside a method that has no locals avoids that.
  #
  # The method is defined through instance_eval of a string, never a block: a
  # block fixes Module.nesting to wherever it is written, so `class Foo` in
  # one file's tests would land in a namespace shared with every other file.
  # Defined this way, constants and methods defined by test code belong to
  # the object's singleton class, isolated per file (or per test in fresh
  # context mode).
  module ScriptBinding
    def self.for(object)
      object.instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def __tryouts_binding__
          binding
        end
      RUBY
      script_binding = object.__tryouts_binding__
      object.singleton_class.send(:remove_method, :__tryouts_binding__)
      script_binding
    end
  end
end
