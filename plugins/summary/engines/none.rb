module Engines
  class None < Base
    url %r{}

    def execute
      raise Nop, "None"
    end
  end
end

