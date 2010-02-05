require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

module Ircbot
  module DM
    dsl_accessor :connection

    def self.included(base)
      base.class_eval do
        extend Connection
        super
      end
    end

    def connect(path = nil)
      @connection ||= self.class.establish_connection(path)
    end

    module Connection
      def establish_connection(path = nil, &block)
        path = path.to_s
        path = 'unknown' if path.empty?
        if DM.connection != path
          DM.connection = path
          path = (path[0] == ?/) ? Pathname(path) : Pathname(Dir.getwd) + "db" + "#{path}.db"
          path = path.expand_path
          path.parent.mkpath
          DataMapper.setup(:default, "sqlite3://#{path}")
        end

        @models.each(&:auto_upgrade!) if @models
        return DataMapper.repository(:default)
      end

      def connect(*models)
        @models = models
      end
    end
  end
end
