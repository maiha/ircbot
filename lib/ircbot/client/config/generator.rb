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
    end
  end
end
