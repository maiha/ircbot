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
    ### Caching

    def clear_cache
      @cache = {}
    end

    def cache(key = nil, &block)
      key = key.to_s
      return @cache ||= {} if key.empty?

      if @cache.has_key?(key)
        @cache[key]
      else
        @cache[key] = block.call
      end
    end

    ######################################################################
    ### Accessors

    def active_names
      cache(:active_names) { active.map(&:plugin_name) }
    end

    def active
      cache(:active) { select(&:running) }
    end

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
      changed!
    end

    def stop(plugin)
      plugin!(plugin).running = false
      changed!
    end

    def delete(plugin)
      name = plugin.is_a?(Plugin) ? plugin.name : plugin.to_s
      plugin!(name)
      @plugins.delete(name)
      changed!
    end

    def changed!
      clear_cache
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
      changed!
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
      Dir.chdir(path.parent) do
        eval(script, Ircbot.toplevel_binding)
      end

      return Object.const_get(class_name).new

    rescue NameError => e
      raise LoadError, "Expected #{path} to define #{class_name} (#{e})"
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
