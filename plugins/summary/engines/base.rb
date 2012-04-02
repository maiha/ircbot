require 'open3'

module Engines
  class Base
    dsl_accessor :url

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

    def execute
      html = fetch(@url)
      html = NKF.nkf("-w", html)
      title, body = parse(html)
      return "[%s] %s" % [title, body]
    end
  end
end
