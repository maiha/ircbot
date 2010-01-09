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
      super

      text = decode(m.params[1].to_s)
      args = [text, m.prefix.nick, m]

      plugins_call_replies(args)
      plugins_call_logs(args)
    end

    private
      def plugins_call_replies(args)
        catch(:halt) do
          plugins.each do |plugin|
            plugins_call_action(:reply, plugin, args, :reply=>true)
          end
        end
      end

      def plugins_call_logs(args)        
        plugins.each do |plugin|
          plugins_call_action(:log, plugin, args)
        end
      end

      def plugins_call_action(type, plugin, args, opts = {})
        plugin.message = args.last
        arity = plugin.method(type).arity rescue return
        reply = plugin.__send__(type, *args[0,arity])
        plugin.message.reply(@client, reply) if opts[:reply]
      rescue Exception => e
        plugin.message.reply(@client, "ERROR: #{e.message}")
        rescue_action type, plugin, e
      end

      def plugins_rescue_action(type, plugin, e)
        p [e.class, e.message, type, plugin]
        at = e.backtraces rescue '(no backtraces)'
        puts at
      end

  end
end

