# -*- coding: utf-8 -*-

module Ircbot
  class Client
    ######################################################################
    ### Event

    event(:ping) {
      if (sec = config.timeout.to_i) > 0
        @kill_myself_at.kill if @kill_myself_at.is_a?(Thread)
        @kill_myself_at = Thread.new { sleep sec; timeouted }
      end
    }

    class Timeouted < RuntimeError; end

    def start
      super
    rescue Exception => e
      sec = [config.wait_before_restart.to_i, 10].max
      sleep sec
      $stderr.puts "Restarting after timeouted"
      retry
    end

    private
      def timeouted
        $stderr.puts "No new pings for #{config.timeout}sec."
        raise Timeouted
      end
  end
end
