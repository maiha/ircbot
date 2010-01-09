# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      class Generator
        attr_reader :nick

        def initialize(options = {})
          @nick = options[:nick]
          @code = options[:code] || read_template

          @nick = current_user + "_bot" if @nick.to_s.empty?
        end

        def execute
          require 'erb'
          erb = ERB.new(@code)
          erb.result(binding)
        end

        private
          def read_template
            path = Ircbot.paths[:config].first + "yml.erb"
            return path.read{}
          end

          def current_user
            require 'etc'
            Etc.getlogin
          rescue Exception
            "unknown"
          end
      end
      def channels
        case (val = super)
        when Array
          val
        else
          val.to_s.split
        end
      end
    end

    ######################################################################
    ### Event

    def on_rpl_welcome(m)
      super

      config.channels.each do |channel|
        post JOIN, channel
      end
    end

    ######################################################################
    ### Command

    def broadcast(text)
      config.channels.each do |channel|
        privmsg channel, text
      end
    end
  end
end
