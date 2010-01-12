# -*- coding: utf-8 -*-

require "ircbot/plugin"
require "ircbot/plugins"

module Ircbot
  class Client < Net::IRC::Client
    class Standalone < Client
      def initialize(*)
        super({})
      end
    end
  end
end

require "ircbot/client/eventable"
require "ircbot/client/logger"
require "ircbot/client/encoding"
require "ircbot/client/commands"
require "ircbot/client/config"
require "ircbot/client/config/channels"
require "ircbot/client/config/plugins"
require "ircbot/client/timeout"
require "ircbot/client/plugins"
