module RSpec
  module Core
    module SharedExampleGroup
      def its(*args, &block)
        describe(args.first) do
          define_method(:subject) { super().send(*args) }
          it(&block)
        end
      end
    end
  end
end

