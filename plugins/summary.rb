#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'ch2'

class SummaryPlugin < Ircbot::Plugin
  class Nop < RuntimeError; end

  def help
    "[Summary] summarize web page (responds to only 2ch)"
  end

  def reply(text)
    url = parse_url(text)
    return once(url) {summarize(url)}
  rescue Nop
    return nil
  end

  private
    def parse_url(text)
      uris = URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}.grep(/2ch/)
      uris.first or raise Nop
    end

    def summarize(url)
      dat = Ch2::Dat.new(url)
      dat.valid? or raise Nop
      return ">> %s" % dat.summarize.gsub(/\s+/m, ' ')
    end

    def once(key, &block)
      @once ||= {}
      raise Nop if @once.has_key?(key)
      return block.call
    ensure
      @once[key] = 1
    end
end


