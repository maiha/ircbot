require 'open3'
require 'digest/sha1'

module Watchdog
  class Updater < Ircbot::Utils::Watcher
    interval 600

    def srcs
      Page.current
    end

    def process(page)
      status = page.to_s
      page.update!
      status = "#{page} (#{page.changed}: #{page.digest})"
      return page.changed
    ensure
      $stderr.puts "#{self.class}#process: #{status}"
    end
  end
end
