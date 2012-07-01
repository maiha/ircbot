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

    def self.command?(name)
      @commands ||= (public_instance_methods - Plugin.public_instance_methods).inject({"setup"=>1, "help"=>1}) {|h,k| h[k.to_s] = 1; h }
      !! @commands[name.to_s]
    end

    def initialize(plugins = nil)
      @plugins = plugins || Plugins.new
      @message = InitialMessage.new(self.class.name)
      @running = false
      @attrs   = Mash.new
    end

    def setup
    end

    ######################################################################
    ### Accessors

    delegate :plugin!, :client, :bot, :config, :to=>"@plugins"
    delegate :debug, :to=>"@plugins"

    def [](key)
      @attrs[key]
    end

    def plugin_name
      @plugin_name ||= Extlib::Inflection.foreign_key(self.class.name).sub(/(_plugin)?_id$/,'')
    end

    def inspect
      "<%sPlugin: %s>" % [running ? '*' : '', plugin_name]
    end

    def to_s
      "%s%s" % [running ? '*' : '', plugin_name]
    end

    def attrs=(hash)
      @attrs = Mash.new(hash)
    end

    ######################################################################
    ### Operations

    def done(text = nil)
      throw :done, text
    end

    def help
      raise "no helps for #{plugin_name}"
    end

    ######################################################################
    ### Messages

    def direct?
      message.channel == config.nick
    end

    def me?
      !! (message.message =~ /\A#{config.nick}\./)
    end

    def nick
      message.prefix.nick
    end

    def command
      (message.message =~ /\A#{config.nick}\./) ? $'.to_s.strip.split.first.to_s : ''
    end

    def arg
      (message.message =~ /\A#{config.nick}\./) ? (a = $'.to_s.strip.split; a.shift; a.join) : ''
    end

    private
      def plugin(name)
        plugin!(name)
      rescue
        Null.new
      end
  end
end
