require 'open3'

module Engines
  class Base
    dsl_accessor :url

    MaxContentLength = 512 * 1024

    def initialize(url)
      @url = url
    end

    def head(url)
      # HTTP/1.1 200 OK
      # Content-Type: text/html; charset=utf-8
      # Date: Sun, 08 Apr 2012 18:08:45 GMT
      # Content-Length: 245091
      # Server: GSE

      curl_options = ["--head"]
      Open3.popen3(*["curl", curl_options, url].flatten) {|i,o,e| o.read }
    end

    def text?(url)
      head(url).to_s =~ %r{^Content-Type:.*text/}
    end

    def fetch(url)
      curl_options = [
                      "--location", "--compressed",
                      "--max-filesize", "%d" % MaxContentLength,
                     ]
      Open3.popen3(*["curl", curl_options, url].flatten) {|i,o,e| o.read }
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
      title = get_title(html)
      body = trim_tags(html)
      return title, body
    end

    def execute
      raise Nop, "Not Text" unless text?(@url)
      html = fetch(@url)
      html = NKF.nkf("-w", html)
      title, body = parse(html)
      return "[%s] %s" % [title, body]
    end
  end
end
