module Ircbot
  def paths
    @paths ||= Mash.new
  end

  def root
    @root || Pathname(Dir.pwd).expand_path
  end

  def system_root
    (Pathname(File.dirname(__FILE__)) + ".." + "..").expand_path
  end

  def root=(value)
    @root = Pathname(value)
  end

  def push_path(type, path)
    paths[type] ||= []
    paths[type] << Pathname(path)
  end

  def glob_for(type, name)
    Array(paths[type]).reverse.select{|p| p.directory?}.map{|d|
      Dir.glob(d + "**/#{name}.*")
    }.flatten.compact.map{|i| Pathname(i)}
  end

  attr_accessor :toplevel_binding

  extend self
end
