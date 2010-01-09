# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      def plugins
        case (val = super)
        when Array
          val
        else
          val.to_s.split
        end
      end
    end
  end
end
