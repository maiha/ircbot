require 'cgi'

module Ircbot
  module Utils
    module HtmlParser
      def get_title(html)
        title = $1.strip if %r{<title>(.*?)</title>}mi =~ html
        title ? trim_tags(title) : ""
      end

      def trim_tags(html)
        html.gsub!(%r{<head.*?>.*?</head>}mi, '')
        html.gsub!(%r{<script.*?>.*?</script>}mi, '')
        html.gsub!(%r{<style.*?>.*?</style>}mi, '')
        html.gsub!(%r{<noscript.*?>.*?</noscript>}mi, '')
        html.gsub!(%r{</?.*?>}, '')
        html.gsub!(%r{<\!--.*?-->}mi, '')
        html.gsub!(%r{<\!\w.*?>}mi, '')
        html.gsub!(/\s+/m, ' ')
        html.strip!
        html = CGI.unescapeHTML(html)
        return html
      end
    end
  end
end
