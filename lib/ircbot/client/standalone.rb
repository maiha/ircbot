module Ircbot
  class Client
    class Standalone < Client
      def initialize(*)
        super({})
      end
    end
  end
end
