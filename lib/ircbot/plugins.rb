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

      load Array(plugins)
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

    def load(plugin)
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
          self << eval_plugin(name)
        rescue Exception => e
          broadcast "Plugin error(#{name}): #{e}[#{e.class}]"
        end
      else
        raise NotImplementedError, "#<< for #{plugin.class}"
      end
      return self
    end
    alias :<< :load

    def eval_plugin(name)
      class_name = plugin_class_name(name)

      if Object.const_defined?(class_name)
        Object.send(:remove_const, class_name)
      end

      path = Ircbot.glob_for(:plugin, name).first or
        raise PluginNotFound, name.to_s

      script = path.read{}
      eval(script, Ircbot.toplevel_binding)

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

      def plugin_class_name(name)
        Extlib::Inflection.camelize(name) + "Plugin"
      end
  end
end
