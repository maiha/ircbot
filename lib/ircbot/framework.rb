module Ircbot
  class << self
    def root
      @root ||= Pathname(File.expand_path(Dir.pwd))
    end
  end
end
