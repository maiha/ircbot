# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      def channels
        case (val = super)
        when Array
          val
        else
          val.to_s.split
        end
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
