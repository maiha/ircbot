require 'open3'
require 'cgi'

module Engines
  class Base
    dsl_accessor :url

    MaxContentLength = 512 * 1024

    def initialize(url, config = {})
      @url = url
      @config = config
    end

    def build_curl_options(options)
      options = options.dup
      if curl_option = @config[:curl_option]
        for key, value in curl_option
          case value
          when TrueClass
            options << "--#{key}"
          else
            options << "--#{key}" << value
          end
        end
      end
      options
    end

    def head(url)
      # HTTP/1.1 200 OK
      # Content-Type: text/html; charset=utf-8
      # Date: Sun, 08 Apr 2012 18:08:45 GMT
      # Content-Length: 245091
      # Server: GSE

      curl_options = build_curl_options [
                                         "--head", "--location",
                                         "--user-agent", "Mozilla",
                                         "--max-time", "30",
                                         "--silent", "--show-error",
                                        ]
      Open3.popen3(*["curl", curl_options, url].flatten) {|i,o,e|
        [o.read, e.read]
      }
    end

    def summarizable?(header)
      if header =~ %r{^Content-Length:\s*(\d+)}i
        if $1.to_i > MaxContentLength
          raise Nop, "Exceed MaxContentLength: #{$1.to_i} bytes"
        end
      end
      header =~ %r{^Content-Type:.*text/}i
    end

    def fetch(url)
      curl_options = build_curl_options [
                                         "--location", "--compressed",
                                         "--user-agent", "Mozilla",
                                         "--max-time", "30",
                                         "--max-filesize", "%d" % MaxContentLength,
                                         "--silent", "--show-error",
                                        ]
      Open3.popen3(*["curl", curl_options, url].flatten) {|i,o,e|
        [o.read, e.read]
      }
    end

    def preprocess_content(content, header)
      NKF.nkf("-w -Z1 --numchar-input --no-cp932", content)
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
      if %r{<title[^>]*>(.*?)</title>}mi =~ html
        title = $1.strip
        title.gsub!(%r{<.*?>}m, '')
        title.gsub!(%r{\s+}m, ' ')
        NKF.nkf("-w -Z3 --numchar-input --no-cp932", title)
      else
        ""
      end
    end

    def get_body(html)
      if /<body.*?>(.*?)<\/body>/im =~ html
        body = $1
      else
        raise Nop, "No Body Found"
      end
      body.gsub!(%r{<!--.*?-->}im, '')
      body.gsub!(%r{<\!\w.*?>}mi, '')
      #body.gsub!(%r{<head.*?>.*?<\/head>}mi, '')
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
      NKF.nkf("-w -Z3 --numchar-input --no-cp932", summary||"")
    end

    def parse(html)
      title = get_title(html)
      body = get_body(html)
      return title, body
    end

    def execute
      header, error = head(@url)
      raise Nop, "Failed to head: #{error}" if header.empty?
      raise Nop, "Not Text" unless summarizable?(header)
      content, error = fetch(@url)
      raise Nop, "Failed to fetch: #{error}" if content.empty?
      html = preprocess_content(content, header)
      title, body = parse(html)
      return "[%s] %s" % [title, body]
    end
  end
end
