module Ircbot
  mattr_accessor :load_paths
  self.load_paths = {}

  class InvalidFilename < SecurityError; end
  class FileNotFound < SecurityError; end

  class Recover < RuntimeError
    attr_reader :wait

    def initialize(wait = 300)
      @wait = wait
    end
  end

  class << self
    def root
      @root || File.expand_path(Dir.pwd)
    end

    def root=(value)
      @root = value
    end

    def push_path(type, path, file_glob = "**/*.rb")
      load_paths[type] = [Pathname(path), file_glob]
    end

    def dir_for(type)
      load_paths[type][0] or
        raise RuntimeError, "directory not found: #{type}"
    end

    def glob_for(type)
      load_paths[type][1]
    end

    def path_for(type, name)
      name = name.to_s
      raise InvalidFilename, name if name =~ %r{\.\.|~|/}

      path = dir_for(type) + name
      path.readable_real? or
        raise FileNotFound, name

      return path
    end
  end
end

