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

class SummaryPlugin < Ircbot::Plugin
  Nop    = Class.new(RuntimeError)

  def help
    "[Summary] summarize web page (responds to only 2ch or https)"
  end

  def reply(text)
    scan_urls(text).each do |url|
      case url
      when /2ch\.net/
        text = once(url) {summarize_2ch(url)}
      when %r{^https:}
        text = once(url) {summarize(url)}
      else
      end
      done(text) if text
    end
    return nil

  rescue Nop
    return nil
  end

  def trim_tags(html)
    html.gsub!(%r{<script.*?>.*?</script>}mi, '')
    html.gsub!(%r{<style.*?>.*?</style>}mi, '')
    html.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
    html.gsub!(%r{</?.*?>}, '')
    html.gsub!(/\s+/m, ' ')
    return html
  end

  def summarize(url)
    html = fetch(url)
    html = trim_tags(html)
    return html
  end

  def summarize_2ch(url)
    dat = Ch2::Dat.new(url)
    dat.valid? or raise Nop
    return ">> %s" % trim_tags(dat.summarize)
  end

  private
    def scan_urls(text, &block)
      URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}
    end

    def fetch(url)
      Open3.popen3("curl", "--location", "--compressed", url) {|i,o,e| o.read }
    end

    def once(key, &block)
      @once ||= {}
      raise Nop if @once.has_key?(key)
      return block.call
    ensure
      @once[key] = 1
    end
end


