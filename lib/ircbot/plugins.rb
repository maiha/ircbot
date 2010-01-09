# -*- coding: utf-8 -*-

module Ircbot
  class Plugins
    include Enumerable

    attr_reader :plugins

    def initialize(client)
      @client = client
      @plugins = []
    end

    def each(&block)
      plugins.__send__(:each, &block)
    end

    def <<(obj)
      case obj
      when String, Symbol
        raise NotImplementedError, "#add"
      when Class
        plugin = obj.new
        plugin.client = @client
        plugins << plugin
      end
    end

    def call_actions(args)
      call_replies(args)
      call_logs(args)
    end

    private
      def call_action(type, plugin, args, opts = {})
        plugin.message = args.last
        arity = plugin.method(type).arity rescue return
        reply = plugin.__send__(type, *args[0,arity])
        plugin.message.reply(@client, reply) if opts[:reply]
      rescue Exception => e
        plugin.message.reply(@client, "ERROR: #{e.message}")
        rescue_action type, plugin, e
      end

      def rescue_action(type, plugin, e)
        p [e.class, e.message, type, plugin]
        at = e.backtraces rescue '(no backtraces)'
        puts at
      end

      def call_replies(args)
        catch(:halt) do
          plugins.each do |plugin|
            call_action(:reply, plugin, args, :reply=>true)
          end
        end
      end

      def call_logs(args)        
        plugins.each do |plugin|
          call_action(:log, plugin, args)
        end
      end
  end
end
