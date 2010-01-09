# -*- coding: utf-8 -*-

module Ircbot
  class Plugins
    include Enumerable

    attr_reader :plugins
    attr_reader :client

    def initialize(client = nil, plugins = nil)
      @client  = client  || Client::Standalone.new
      @plugins = plugins || []
    end

    def each(&block)
      plugins.__send__(:each, &block)
    end

    def [](key)
      find{|plugin| plugin.plugin_name == key.to_s}
    end

    def <<(plugin)
      case plugin
      when Ircbot::Plugin
        plugin.plugins = self
        plugins << plugin
      when Class
        if plugin.ancestors.include?(Ircbot::Plugin)
          self << plugin.new(self)
        else
          raise ArgumentError, "#{plugin} is not Ircbot::Plugin"
        end
      else
        raise NotImplementedError, "#<< for #{plugin.class}"
      end
      return self
    end
  end
end
