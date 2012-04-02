#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'nkf'
require 'ch2'
require 'summarizer'

######################################################################
# [Install]
#
# apt-get install curl
#

class NormalSummarizer < Summarizer
  register %r{^https://}
end

class Ch2Summarizer < Summarizer
  register %r{^http://[^./]+\.2ch\.net}

  def summarize
    dat = Ch2::Dat.new(@url)
    dat.valid? or raise Nop
    return ">> %s" % trim_tags(dat.summarize)
  end
end

class TwitterSummarizer < Summarizer
  register %r{twitter.com}

  def initialize(url)
    super
    @url = normalize_url(@url)
  end

  def normalize_url(url)
    return url.sub(%r{#!/}, '').sub(%r{//(twitter.com/)}, "//mobile.\\1")
  end
end


class SummaryPlugin < Ircbot::Plugin
  Nop = Summarizer::Nop

  def help
    "[Summary] summarize web page (responds to only 2ch or https)"
  end

  def reply(text)
    scan_urls(text).each do |url|
      summary = once(url) {
        begin
          summarizer = Summarizer.create(url)
          summarizer.summarize
        rescue Summarizer::NotImplementedError => e
          nil
        end
      }
      done(summary) if summary
    end
    return nil

  rescue Nop
    return nil
  end

  private
    def scan_urls(text, &block)
      URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}
    end

    def once(key, &block)
      @once ||= {}
      raise Nop if @once.has_key?(key)
      return block.call
    ensure
      @once[key] = 1
    end
end


if __FILE__ == $0
  p summarizer = Summarizer.create(ARGV.shift)
  puts summarizer.summarize
end
