# -*- coding: utf-8 -*-

module Ircbot
  class Client
    def normalize_message_text(text, size = 120)
      a = text.to_s.split(//)
      if a.size > size
        return a[0..size].join + "..."
      else
        return text.to_s
      end
    end
  end
end

