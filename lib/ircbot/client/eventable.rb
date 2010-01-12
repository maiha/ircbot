module Ircbot
  class Client
    include Extlib::Hook

    class << self
      def event(name, &block)
        name = "on_#{name}".intern
        unless instance_methods.include?(name.to_s)
          define_method(name){|m|}
        end
        before name, &block
      end
    end

    # escape from nil black hole
    private
      def method_missing(name, *args)
        raise NameError, "undefined local variable or method `#{name}' for #{self}"
      end
  end
end
