require 'dsl_accessor'
require 'extlib'

module Engines
  Mapping  = []
  Loaded   = {}
  NotFound = Class.new(RuntimeError)

  class NotImplementedError < NotImplementedError; end
  class Nop < NotImplementedError; end

  def self.create(url)
    for pattern, klass in Mapping
      return klass.new(url, @engine_config) if pattern =~ url
    end
    raise NotImplementedError, "[BUG] Not supported URL: %s" % url
  end

  def self.[](name)
    unless loaded?(name)
      raise NotFound, name.to_s
    end
    instance_eval(Extlib::Inflection.camelize(name))
  end

  def self.setup(names = [], engine_config = nil)
    @engine_config = engine_config || {}
    unless @engine_config.is_a?(Hash)
      raise ArgumentError, "Engines.setup expects Hash as config, but got %s" % [@engine_config.class]
    end
    Mapping.clear
    names = (%w( none ) + [names]).flatten.uniq
    debug "[Summary] Engines.setup(%s)" % names.inspect
    names.each do |name|
      klass = self[name]
      Mapping.unshift [klass.url, klass]
    end
  end

  # load ruby library
  def self.load(name)
    name = name.to_s
    return false if loaded?(name)

    file = File.dirname(__FILE__) + "/engines/#{name}.rb"
    Kernel.load(file)

    Loaded[name] = Time.now
  end
  def self.loaded?(name) Loaded[name]; end

  def self.load_engines
    load :base
    load :none
    Dir.glob(File.dirname(__FILE__) + "/engines/*.rb").sort.each do |file|
      name = File.basename(file, ".*")
      load(name)
    end
  end

  # logger
  def self.debug(msg)
    puts msg.to_s
  end
end

Engines.load_engines
