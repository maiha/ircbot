module Ircbot
  class << self
    attr_accessor :load_paths

    def root
      @root || File.expand_path(Dir.pwd)
    end

    def root=(value)
      @root = value
    end

    def dir_for(type)
      load_paths[type].first
    end

    def push_path(type, path, file_glob = "**/*.rb")
      load_paths[type] = [path, file_glob]
    end
  end
end

