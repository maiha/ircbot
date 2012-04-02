require 'dsl_accessor'
require 'extlib'

module Summarizers
  Mapping = []

  class NotImplementedError < NotImplementedError; end
  class Nop < NotImplementedError; end

  def self.create(url)
    for pattern, klass in Mapping
      return klass.new(url) if pattern =~ url
    end
    raise NotImplementedError, "[BUG] Not supported URL: %s" % url
  end

  # load ruby library and register its url
  def self.register(name)
    load File.dirname(__FILE__) + "/summarizers/#{name}.rb"
    klass = instance_eval(Extlib::Inflection.camelize(name))
    Mapping.unshift [klass.url, klass] unless klass == Base
  end

  register("base")
  register("none")
  register("https")
  register("ch2")
  register("twitter")
end

