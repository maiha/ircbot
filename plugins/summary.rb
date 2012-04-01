#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'nkf'
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

  class NotImplementedError < NotImplementedError; end

  Nop = Class.new(RuntimeError)

  class << self
    def register(url_pattern)
      Mapping.unshift [url_pattern, self]
    end

    def create(url)
      for pattern, klass in Mapping
        return klass.new(url) if pattern =~ url
      end
      raise NotImplementedError, "Not supported URL: %s" % url
    end
  end


  Quote = ">>"
  MaxContentLength = 512 * 1024

  def initialize(url)
    @url = url
  end

  def fetch(url)
    curl_options = [
      "--location", "--compressed",
      "--max-filesize", "%d" % MaxContentLength,
    ]
    Open3.popen3(*["curl", curl_options, url].flatten) {|i,o,e| o.read }
  end

  def get_content_type(html)
    content_type = Open3.popen3("file", "-b", "--mime-type", "-") {|i,o,e|
      i.write(html)
      i.close
      o.read
    }
    content_type.chomp
  end

  def get_title(html)
    title = $1.strip if %r{<title>(.*?)</title>}mi =~ html
    trim_tags(title)
  end

  def trim_tags(html)
    html.gsub!(%r{<head.*?>.*?</head>}mi, '')
    html.gsub!(%r{<script.*?>.*?</script>}mi, '')
    html.gsub!(%r{<style.*?>.*?</style>}mi, '')
    html.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
    html.gsub!(%r{</?.*?>}, '')
    html.gsub!(%r{<\!--.*?-->}mi, '')
    html.gsub!(/\s+/m, ' ')
    html.strip!
    return html
  end

  def parse(html)
    content_type = get_content_type(html)
    unless %r{^(?:text/|application/xml)}i =~ content_type
      raise Nop, "Not HTML: #{content_type}"
    end
    title = get_title(html)
    body = trim_tags(html)
    return title, body
  end

  def summarize
    html = fetch(@url)
    html = NKF.nkf("-w", html)
    title, body = parse(html)
    return "%s [%s] %s" % [Quote, title, body]
  end
end

class NormalSummarizer < Summarizer
  register %r{^https://}
end

class Ch2Summarizer < Summarizer
  register %r{^http://\+\.2ch\.net}

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
