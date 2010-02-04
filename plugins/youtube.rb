#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'open-uri'
require 'nokogiri'

class YouTubeContentParser
  class CannotParse < RuntimeError; end

  attr_reader :t
  attr_reader :video_id

  def initialize(html)
    @html = html
    extract_header(:t)
    extract_header(:video_id)
  end

  def get_video
    "http://youtube.com/get_video.php?t=#{t}&video_id=#{video_id}&fmt=18"
  end

  private
    def doc
      @doc ||= Nokogiri::HTML(@html)
    end

    def extract_header(key, opts = {})
      from  = opts[:from] || key
      regex = /"#{from}":\s*"(.*?)"/
      array = @html.scan(regex).flatten
      case array.size
      when 0
        # error
      when 1
        instance_eval("@#{key} = array.first")
      else
        # video_id is ambigous. so strictly parse html with Nokogiri
        doc.xpath('//head/script').each do |e|
          value = e.html.scan(regex).flatten.first
          instance_eval("@#{key} ||= value") and break
        end
      end

      raise CannotParse, key.to_s unless instance_variable_get("@#{key}")
    end
end

class YouTubePlugin < Ircbot::Plugin
  def help
    "[YouTube] automatically download youtube videos"
  end

  def reply(text)
    return nil

#     url = URI.extract(text.to_s).grep(%r{^http://www\.youtube}).first
#     download(url)
  end

  private
    def download(url)
      return nil unless url

      html   = open(url).read{}
      parser = YouTubeContentParser.new(html)
    end
end

