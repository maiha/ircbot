require 'open3'
require 'cgi'

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

    def trim_tags(html)
      html.gsub!(%r{<head[^>]*>.*?</head>}mi, '')
      html.gsub!(%r{<script.*?>.*?</script>}mi, '')
      html.gsub!(%r{<style.*?>.*?</style>}mi, '')
      html.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
      html.gsub!(%r{</?.*?>}, '')
      html.gsub!(%r{<\!--.*?-->}mi, '')
      html.gsub!(%r{<\!\w.*?>}mi, '')
      html.gsub!(%r{\s+}m, ' ')
      html.strip!
      html = CGI.unescapeHTML(html)
      return html
    end

    def get_title(html)
      if %r{<title>(.*?)</title>}mi =~ html
        title = $1.strip
        title.gsub!(%r{<.*?>}m, '')
        title.gsub!(%r{\s+}m, ' ')
        CGI.unescapeHTML(title)
      else
        ""
      end
    end

    def get_body(html)
      html = NKF.nkf("-w -Z1", html)
      if /<body.*?>(.*?)<\/body>/im =~ html
        body = $1
      else
        raise Nop, "No Body Found"
      end
      body.gsub!(%r{<!--.*?-->}im, '')
      body.gsub!(%r{<\!\w.*?>}mi, '')
#      body.gsub!(%r{<head.*?>.*?<\/head>}mi, '')
      body.gsub!(%r{<head[^>]*>.*?<\/head>}mi, '')
      body.gsub!(%r{<script.*?>.*?<\/script>}mi, '')
      body.gsub!(%r{<style.*?>.*?<\/style>}mi, '')
      body.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
      body.gsub!(%r{(:?<a.*?>|<\/a>)}mi, '')
      body.gsub!(%r{(:?<font.*?>|<\/font>)}mi, '')
      body.gsub!(%r{<img.*?/?>}mi, '')
      body.gsub!(%r{(:?<b>|<\/b>|<i>|<\/i>|<u>|<\/u>|<p>|<\/p>|<\/li>)}mi,'')
      body.gsub!(%r{(<(:?br)(:?\s+/)?>)}mi,'')
      body.gsub!(%r{(:?<\/?h[1-6]>)}mi, ' ')
      body.gsub!(%r{<li>}mi, ' * ')
      elements = body.split(/<.*?>/mi)
      elements.each { |item| item.gsub!(/\s+/, ' ') }
      elements.each { |item| item.strip! }
      elements.reject! { |item| item.empty? }
      summary = elements.max_by {|e| e.size }
      return summary ? CGI.unescapeHTML(summary) : ""
    end

    def parse(html)
      title = get_title(html)
      body = get_body(html)
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
