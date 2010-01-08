# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      def channels
        Array(super)
      end
    end

    def on_rpl_welcome(m)
      super

      config.channels.each do |channel|
        post JOIN, channel
      end
    end
  end
end
