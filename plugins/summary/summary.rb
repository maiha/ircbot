#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'nkf'
require 'summarizers'

######################################################################
# [INSTALL]
#   apt-get install curl
#
# [TEST]
#   cd plugins/summary
#   rspec -c spec

class SummaryPlugin < Ircbot::Plugin
  Quote = ">> "

  def help
    "[Summary] summarize web page (responds to only 2ch or https)"
  end

  def reply(text)
    scan_urls(text).each do |url|
      summary = once(url) {
        Summarizers.create(url).execute
      }
      done(Quote + summary) if summary
    end
    return nil

  rescue Summarizers::NotImplementedError => e
    $stderr.puts e
    return nil
  rescue Summarizers::Nop
    return nil
  end

  private
    def scan_urls(text, &block)
      URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}
    end

    def once(key, &block)
      @once ||= {}
      raise Summarizers::Nop if @once.has_key?(key)
      return block.call
    ensure
      @once[key] = 1
    end
end


if __FILE__ == $0
  p summarizer = Summarizers.create(ARGV.shift)
  puts summarizer.execute
end
