# -*- coding: utf-8 -*-

module Ircbot
  class Agent
    class ClientNotFound < RuntimeError; end

    class Null
      private
        def method_missing(*)
          self
        end
    end

    attr_accessor :message
    attr_accessor :args

    def initialize(*args)
      @args = args
    end

    def client=(client)
      @client = client
    end

    private
      def client
        @client or raise ClientNotFound
      end

      def agent!(name)
        client.agent!(name)
      end

      def agent(name)
        agent!(name)
      rescue ClientNotFound
        Null.new
      end

      def direct?
        message.channel == client.nick
      end
  end
end
