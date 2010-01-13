# -*- coding: utf-8 -*-

module Ircbot
  class Plugin
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
    attr_accessor :running
    attr_accessor :plugin_name

    def initialize(plugins = nil)
      @plugins = plugins || Plugins.new
      @message = InitialMessage.new(self.class.name)
      @running = false
    end

    ######################################################################
    ### Accessors

    delegate :plugin!, :client, :bot, :config, :to=>"@plugins"
    delegate :debug, :to=>"@plugins"

    def plugin_name
      @plugin_name ||= Extlib::Inflection.foreign_key(self.class.name).sub(/(_plugin)?_id$/,'')
    end

    def inspect
      "<%sPlugin: %s>" % [running ? '*' : '', plugin_name]
    end

    def to_s
      "%s%s" % [running ? '*' : '', plugin_name]
    end

    ######################################################################
    ### Operations

    def help
      raise "no helps for #{plugin_name}"
    end

    private
      def plugin(name)
        plugin!(name)
      rescue
        Null.new
      end

      def direct?
        message.channel == config.nick
      end

      def nick
        message.prefix.nick
      end
  end
end
