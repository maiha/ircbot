require 'ch2'

module Engines
  class Ch2 < Base
    url %r{^http://[^./]+\.2ch\.net}

    def execute
      dat = ::Ch2::Dat.new(@url)
      dat.valid? or raise Nop
      return trim_tags(dat.summarize)
    end
  end
end

