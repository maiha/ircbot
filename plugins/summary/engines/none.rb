module Engines
  class None < Base
    url %r{}

    def execute
      raise Nop
    end
  end
end

