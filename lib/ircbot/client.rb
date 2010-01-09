# -*- coding: utf-8 -*-

require "ircbot/plugin"
require "ircbot/plugins"

module Ircbot
  class Client < Net::IRC::Client

    # escape from nil black hole
    def method_missing(name, *args)
      case name.to_s
      when /^on_/
        # nop for calling super from subclass
      else
        raise NameError, "undefined local variable or method `#{name}' for #{self}"
      end
    end

    class Standalone < Client
      def initialize(*)
        super({})
      end
    end
  end
end

require "ircbot/client/encoding"
require "ircbot/client/commands"
require "ircbot/client/config"
require "ircbot/client/config/channels"
require "ircbot/client/config/plugins"
require "ircbot/client/plugins"
