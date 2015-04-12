require "strscan"

module Engines
  class Twitter < Base
    url %r{twitter\.com}

    def initialize(url, config)
      super
      @single_tweet = (%r#/status(?:es)?/\d+# =~ @url) ? true : false
      @url = normalize_url(@url)
    end

    def normalize_url(url)
      # change to the mobile version because it is easy to parse content
      url.sub(%r{#!/}, '').sub(%r{//(?:\w+\.)?(twitter.com/)}, "//mobile.\\1")
    end

    def get_main_tweet(html)
      s = StringScanner.new(html)
      s.scan_until(%r#<table\s+class="main-tweet"[^>]*>#)
      #p s
      fragment = s[0]
      table_depth = 1
      while s.rest?
        if chunk = s.scan_until(%r#<(/)?table[^>]*>#)
          #p ["TABLE", s[1], s]
          unless s[1]
            fragment << chunk
            table_depth += 1
          else
            fragment << chunk
            table_depth -= 1
            if table_depth < 1
              break
            end
          end
        else
          # maybe bug
          #p ["ELSE", s]
          break
        end
      end
      fragment
    end

    def get_body(html)
      body_html =
        if @single_tweet
          get_main_tweet(html)
        else
          html
        end
      super(body_html)
    end
  end
end
