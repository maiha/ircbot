# -*- coding: utf-8 -*-

module Ircbot
  class Client
    def synchronize(&block)
      @lock.synchronize(&block)
    end

    def parallel(&block)
      Thread.new(&block)
    end
  end
end

