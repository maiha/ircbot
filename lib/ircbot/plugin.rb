# -*- coding: utf-8 -*-

module Ircbot
  class Plugin
    class NotConnected < RuntimeError; end

    class Null
      def method_missing(*)
        self
      end
    end

    class InitialMessage < Net::IRC::Message
      def initialize(nick = nil)
        super nick, "PRIVMSG", ["#channel", "(initialize)"]
      end
    end

    attr_accessor :message
    attr_accessor :plugins

    def initialize(plugins = nil)
      @plugins = plugins || Plugins.new
      @message = InitialMessage.new(self.class.name)
    end

    ######################################################################
    ### Accessors

    delegate :plugin!, :to=>"@plugins"

    def plugin_name
      @plugin_name ||= Extlib::Inflection.foreign_key(self.class.name).sub(/(_plugin)?_id$/,'')
    end

    def inspect
      "<Plugin: %s>" % plugin_name
    end

    private
      def plugin!(name)
        @plugins[name] or raise NotConnected
      end

      def plugin(name)
        plugin!(name)
      rescue NotConnected
        Null.new
      end

      def direct?
        message.channel == plugins.client.config.nick
      end
  end
end
