module Ircbot
  module Utils
    class Watcher
      dsl_accessor :interval, 60, :instance=>true
      dsl_accessor :callback, proc{|e| puts e}, :instance=>true

      def initialize(options = {})
        interval options[:interval] || self.class.interval
        callback options[:callback] || self.class.callback
      end

      def srcs
        return []
      end

      def process(src)
        return true
      end

      def run
        loop do
          srcs.each do |src|
            if process(src)
              callback.call(src)
            end
          end
          sleep interval
        end
      end

      def start
        Thread.new{ run }
      end
    end
  end
end
