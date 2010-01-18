# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Accessors

    def plugins
      @plugins ||= Plugins.new(self, config.plugins)
    end

    delegate :plugin!, :plugin, :to=>"plugins"


    ######################################################################
    ### Events

    event(:privmsg) {|m|
      text = decode(m.params[1].to_s)
      args = [text, m.prefix.nick, m]

      plugins_call_replies(args, m)
    }

    private
      def plugins_call_replies(args, m)
        text = catch(:done) do
          plugins.active.each do |plugin|
            plugins_call_action(:reply, plugin, args, m, :reply=>true)
          end
          return true
        end
        m.reply(self, text) if text
      end

      def plugins_call_logs(args)        
        raise NotImplementedError, "obsoleted"
        plugins.active.each do |plugin|
          plugins_call_action(:log, plugin, args)
        end
      end

      def plugins_call_action(type, plugin, args, m, opts = {})
        plugin.message = m
        arity = plugin.method(type).arity rescue return
        reply = plugin.__send__(type, *args[0,arity])
        m.reply(self, reply) if opts[:reply]
      rescue Exception => e
        type = (e.class == RuntimeError) ? 'Error' : "#{e.class}"
        text = (type == e.message) ? '' : e.message
        m.reply(self, "#{type}: #{text}")
        plugins_rescue_action type, plugin, e
      end

      def plugins_rescue_action(type, plugin, e)
        p [e.class, e.message, type, plugin]
        at = e.backtraces rescue '(no backtraces)'
        puts at
      end

  end
end

