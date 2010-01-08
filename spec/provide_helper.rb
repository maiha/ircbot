######################################################################
### provide matcher
Spec::Matchers.define :provide do |expected|
  match do |obj|
    (obj.public_methods + obj.protected_methods + obj.private_methods).include?(expected.to_s)
  end
end

module Spec
  module Example
    module Subject
      module ExampleGroupMethods
        # == Examples
        #
        #   describe User do
        #     subject { User.new }
        #     provide :name
        #
        #       [intead of]
        #
        #     it "should provide #name" do
        #       methods = subject.public_methods + subject.protected_methods + subject.private_methods
        #       methods.should include("name")
        #     end
        #   end
        #
        def provide(name)
          it "should provide ##{name}" do
            subject.should provide(name)
          end
        end
      end
    end
  end
end

