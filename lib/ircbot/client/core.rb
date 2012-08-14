require 'thread'

module Ircbot
  class Client < Net::IRC::Client
    def initialize(hash)
      super(hash[:host], hash[:port], hash)
      @config = Config.new(hash)
      @lock   = Mutex.new
    end
  end
end
