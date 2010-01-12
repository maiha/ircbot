# -*- coding: utf-8 -*-

module Ircbot
  class Client
    module Timeout
      ######################################################################
      ### Event

      def on_ping(m)
        super

        if config.timeout
          kill_myself_after(config.timeout.to_i)
        end
      end

      private
        def kill_myself_after(sec)
          if @kill_myself_at.is_a?(Thread)
            @kill_myself_at.kill
          end
          @kill_myself_at = Thread.new {
            sleep sec
            $stderr.puts "No new pings for #{sec}sec."
            timeouted
          }
        end

        def timeouted
          exit
        end
    end

    include Timeout
  end
end
