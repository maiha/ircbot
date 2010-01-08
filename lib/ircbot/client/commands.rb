# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Convinient access to commands

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

