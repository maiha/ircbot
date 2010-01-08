# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      def initialize(obj)
        @obj = obj
      end

      def method_missing(*args)
        @obj.__send__(*args)
      end
    end
    
    def initialize(config)
      super(config[:server], config[:port], config)
    end

    def config
      @config ||= Config.new(opts)
    end
  end
end
