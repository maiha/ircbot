module Summarizers
  class Twitter < Base
    url %r{twitter\.com}

    def initialize(url)
      super
      @url = normalize_url(@url)
    end

    def normalize_url(url)
      return url.sub(%r{#!/}, '').sub(%r{//(twitter.com/)}, "//mobile.\\1")
    end
  end
end


