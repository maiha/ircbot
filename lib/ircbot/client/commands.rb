# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Convinient access to commands

    def post(command, *params)
      if params[1]
        params[1] = encode(params[1]).strip
        if config.multiline
          params[1].split(/\n/).compact.each do |text|
            params[1] = text
            super(command, *params)
          end
          return
        end
      end
        
      super(command, *params)
    end

    def notice(channel, text)
      text = encode(text)
      post NOTICE, channel, text
    end

    def privmsg(channel, text)
      text = encode(text)
      post PRIVMSG, channel, text
    end
  end
end

