# -*- coding: utf-8 -*-

module Ircbot
  class PluginNotFound < RuntimeError; end

  class Plugins
    attr_reader :plugins
    attr_reader :client
    delegate :config, :debug, :to=>"client"

    def initialize(client = nil, plugins = nil)
      @client  = client  || Client::Standalone.new
      @plugins = Dictionary.new

      load_plugins Array(plugins)
    end

    ######################################################################
    ### Enumerable

    include Enumerable

    def each(&block)
      plugins.values.__send__(:each, &block)
    end

    ######################################################################
    ### Accessors

    def plugin!(plugin)
      case plugin
      when String, Symbol
        @plugins[plugin.to_s] or raise PluginNotFound, plugin.to_s
      when Plugin
        plugin
      else
        raise PluginNotFound, "#{plugin.class}(#{plugin})"
      end
    end
    alias :[] :plugin!

    def plugin(name)
      plugin!(name) rescue nil
    end

    def bot
      client
    end

    ######################################################################
    ### Operations

    def start(plugin)
      plugin!(plugin).running = true
    end

    def stop(plugin)
      plugin!(plugin).running = false
    end

    def delete(plugin)
      name = plugin.is_a?(Plugin) ? plugin.name : plugin.to_s
      plugin!(name)
      @plugins.delete(name)
    end

    ######################################################################
    ### IO

    def load_plugins(plugin)
      case plugin
      when Array
        plugin.each do |name|
          self << name
        end
      when Plugin
        plugin.plugins = self
        plugins[plugin.plugin_name] = plugin
        plugin.running = true
      when Class
        if plugin.ancestors.include?(Ircbot::Plugin)
          self << plugin.new(self)
        else
          raise ArgumentError, "#{plugin} is not Ircbot::Plugin"
        end
      when String, Symbol
        begin
          name = plugin.to_s
          self << load(name)
        rescue Exception => e
          broadcast "Plugin error(#{name}): #{e}[#{e.class}]"
        end
      else
        raise NotImplementedError, "#<< for #{plugin.class}"
      end
      return self
    end
    alias :<< :load_plugins

    def load(name)
      path = Ircbot.glob_for(:plugin, name).first or
        raise PluginNotFound, name.to_s

      script = path.read{}
      eval(script, Ircbot.toplevel_binding)

      class_name = Extlib::Inflection.camelize(name) + "Plugin"
      return Object.const_get(class_name).new

    rescue NameError => e
      raise LoadError, "Expected #{path} to define #{class_name} (#{e})"
    end

    def active
      select(&:running)
    end

    def inspect
      plugins.values.inspect
    end

    private
      def broadcast(text)
        p text
      end
  end
end
