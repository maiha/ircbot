# -*- coding: utf-8 -*-

module Ircbot
  class AgentManager
    include Enumerable

    attr_reader :agents

    def initialize(client)
      @client = client
      @agents = []
    end

    def each(&block)
      agents.__send__(:each, &block)
    end

    def <<(obj)
      case obj
      when String, Symbol
        raise NotImplementedError, "#add"
      when Class
        agent = obj.new
        agent.client = @client
        agents << agent
      end
    end

    def call_actions(args)
      call_replies(args)
      call_logs(args)
    end

    private
      def call_action(type, agent, args, opts = {})
        agent.message = args.last
        arity = agent.method(type).arity rescue return
        reply = agent.__send__(type, *args[0,arity])
        agent.message.reply(@client, reply) if opts[:reply]
      rescue Exception => e
        agent.message.reply(@client, "ERROR: #{e.message}")
        rescue_action type, agent, e
      end

      def rescue_action(type, agent, e)
        p [e.class, e.message, type, agent]
        at = e.backtraces rescue '(no backtraces)'
        puts at
      end

      def call_replies(args)
        catch(:halt) do
          agents.each do |agent|
            call_action(:reply, agent, args, :reply=>true)
          end
        end
      end

      def call_logs(args)        
        agents.each do |agent|
          call_action(:log, agent, args)
        end
      end
  end
end
