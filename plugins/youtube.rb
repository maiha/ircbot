#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'
require 'uri'
require 'net/http'
require 'rack'

class YoutubePlugin < Ircbot::Plugin
  def help
    "[YouTube] automatically download youtube videos"
  end

  def reply(text)
    url = URI.extract(text.to_s).grep(%r{^http://www\.youtube}).first
    request_download(url)
  end

  private
    def request_download(url)
      return nil unless url

      escaped = Rack::Utils.escape(url)
      http = Net::HTTP.new('localhost', 9111)
      response = http.post('/register', "url=#{url}")
      if response.code == '200'
        return nil
      else
        reason = "%s: %s" % [response.code, response.body.to_s.split(/\n/).first]
        return "ダウンロード登録失敗: #{reason}"
      end
    end
end

