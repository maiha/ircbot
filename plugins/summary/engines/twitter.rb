module Engines
  class Twitter < Base
    url %r{twitter\.com}

    def initialize(url, config)
      super
      @url = normalize_url(@url)
    end

    def normalize_url(url)
      return url.sub(%r{#!/}, '').sub(%r{//(?:\w+\.)?(twitter.com/)}, "//mobile.\\1")
    end
  end
end


