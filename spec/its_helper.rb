module Spec
  module Example
    module Subject
      module ExampleGroupMethods
        def its(*args, &block)
          describe(args.first) do
            define_method(:subject) { super().send(*args) }
            it(&block)
          end
        end
      end
    end
  end
end

