# -*- coding: utf-8 -*-

module Ircbot
  class Plugin
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

      def plugin!(name)
        client.plugin!(name)
      end

      def plugin(name)
        plugin!(name)
      rescue ClientNotFound
        Null.new
      end

      def direct?
        message.channel == client.nick
      end
  end
end
