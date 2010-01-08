# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Accessors

    def agents
      @agents ||= AgentManager.new(self)
    end

    def agent!(name)
      pattern = (name.is_a?(Regexp) ? name : /^#{Regexp.escape(name.to_s)}$/)
      name = name.to_s
      agents.each do |cpi|
        return cpi if pattern === cpi.class.name
      end
      raise "AgentNotFound: #{name}"
    end

    ######################################################################
    ### Events

    def on_privmsg(m)
      text = decode(m.params[1].to_s)
      args = [text, m.prefix.nick, m]
      agents.call_actions(args)
    end
  end
end

