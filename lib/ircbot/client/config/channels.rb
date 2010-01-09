# -*- coding: utf-8 -*-

module Ircbot
  class Client

    ######################################################################
    ### Config

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

    ######################################################################
    ### Event

    def on_rpl_welcome(m)
      super

      config.channels.each do |channel|
        post JOIN, channel
      end
    end

    ######################################################################
    ### Command

    def broadcast(text)
      config.channels.each do |channel|
        privmsg channel, text
      end
    end
  end
end
