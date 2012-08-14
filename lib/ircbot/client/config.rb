# -*- coding: utf-8 -*-

module Ircbot
  class Client
    class Config
      ######################################################################
      ### Reader
      def self.read(path)
        path = Pathname(path)
        ext  = path.extname.delete(".")
        ext  = "yml" if ext.empty?

        reader = "read_#{ext}"
        if respond_to?(reader)
          Mash.new(__send__(reader, path))
        else
          raise NotImplementedError, "Cannot read #{path}: Format(#{ext})is not supported"
        end
      end

      def self.read_yml(path)
        require 'yaml'
        path = Pathname(path)
        YAML.load(path.read{})
      end

      ######################################################################
      ### Config
      def initialize(obj)
        @obj = Mash.new(obj)
      end

      def [](key)
        @obj[key]
      end

      private
        def method_missing(name, *args)
          if args.empty?
            self[name]
          else
            super
          end
        end
    end
    
    def self.from_file(path)
      new(Config.read(path))
    end

    attr_reader :config
  end
end
