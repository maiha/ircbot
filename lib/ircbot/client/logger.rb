# -*- coding: utf-8 -*-

module Ircbot
  class Client
    def debug(text)
      p [:debug, text]
    end
  end
end
