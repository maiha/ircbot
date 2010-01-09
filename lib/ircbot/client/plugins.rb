# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Accessors

    def plugins
      @plugins ||= Plugins.new(self)
    end

    def plugin!(name)
      pattern = (name.is_a?(Regexp) ? name : /^#{Regexp.escape(name.to_s)}$/)
      name = name.to_s
      plugins.each do |cpi|
        return cpi if pattern === cpi.class.name
      end
      raise "PluginNotFound: #{name}"
    end

    ######################################################################
    ### Events

    def on_privmsg(m)
      text = decode(m.params[1].to_s)
      args = [text, m.prefix.nick, m]
      plugins.call_actions(args)
    end
  end
end

