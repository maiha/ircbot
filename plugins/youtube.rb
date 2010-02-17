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
#      http = Net::HTTP.new('localhost', 3058)
      tags = nick.to_s.gsub(/[0-9_]/,'')
      response = http.post('/request', "url=#{escaped}&tags=#{tags}")
      summary  = response.body.to_s.split(/\n/).first
      case response.code
      when '200'
        return once("DL登録完了: #{summary}")
      when '304'
        return once("DL済: #{summary}")
      else
        reason = "%s: %s" % [response.code, summary]
        return "DL登録失敗: #{reason}"
      end
    rescue Errno::ECONNREFUSED
      return once("ダウンロードサーバが起動してません")
    end

    def once(text)
      text = text.to_s.strip
      @report_once ||= {}
      if @report_once[text]
        return nil
      else
        @report_once[text] = Time.now
        return text
      end
    end
end

