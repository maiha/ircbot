#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'ch2'
require 'escape'
require 'open3'

######################################################################
# [Install]
#
# gem install escape -V
# apt-get install curl
#

class Summarizer
  Mapping = []

  class << self
    def register(url_pattern)
      Mapping.unshift [url_pattern, self]
    end

    def create(url)
      for pattern, klass in Mapping
        break if pattern =~ url
      end
      klass.new(url)
    end
  end


  Quote = ">>"

  def initialize(url)
    @url = url
  end

  def fetch(url)
    Open3.popen3("curl", "--location", "--compresse", url) {|i,o,e| o.read }
  end

  def get_title(html)
    return $1.strip if %r{<title>(.*?)</title>}mi =~ html
  end

  def trim_tags(html)
    html.gsub!(%r{<head.*?>.*?</head>}mi, '')
    html.gsub!(%r{<script.*?>.*?</script>}mi, '')
    html.gsub!(%r{<style.*?>.*?</style>}mi, '')
    html.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
    html.gsub!(%r{</?.*?>}, '')
    html.gsub!(/\s+/m, ' ')
    html.strip!
    return html
  end

  def parse(html)
    title = get_title(html)
    body = trim_tags(html)
    return title, body
  end

  def summarize
    html = fetch(@url)
    title, body = parse(html)
    return "%s [%s] %s" % [Quote, title, body]
  end
end

class NormalSummarizer < Summarizer
  register %r{^https?://}
end

class Ch2Summarizer < Summarizer
  register %r{2ch\.net}

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
  Nop    = Class.new(RuntimeError)

  def help
    "[Summary] summarize web page (responds to only 2ch or https)"
  end

  def reply(text)
    scan_urls(text).each do |url|
      summary = once(url) {
        summarizer = Summarizer.create(url)
        summarizer.summarize
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
