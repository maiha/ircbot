## -*- coding: utf-8 -*-
# ordered_hash.rb
# Author:  
# Created: Tue Jul 24 18:52:49 2001

class Ircbot::OrderedHash < Hash
  def self.[] (*array)
    size = array .size
    if size % 2 == 0
      hash = self .new
      (size / 2) .times do |index|
	key, value = array[index*2,2]
	hash[key] = value
      end
      hash
    else
      super
    end
  end

  def initialize(*args)
    super
    @store_order = []
  end

  def []= (key, value)
    unless self .has_key? key
      @store_order << key
    end
    super
  end

  def keys
    @store_order
  end

  def each
    keys .each do |key|
      yield(key, self[key])
    end
  end
  alias :each_pair :each

  def delete (key)
    @store_order .delete(key)
    super
  end

  def each_value
    keys .each do |key|
      yield(self[key])
    end
  end

  def collect
    keys .collect do |key|
      yield(key, self[key])
    end
  end

  def to_a
    keys .collect do |key|
      [key, self[key]]
    end
  end

  # 先頭に追加する。
  def unshift (key, val)
    self[key] = val
    @store_order .delete key
    @store_order .unshift key
    val
  end

  # 指定されたキーを持つ要素の添字を返す。(Array#index 相当の機能)
  def index_of_key (value)
    keys .index value
  end

  def position (value)
    keys .each_with_index do |key, i|
      return i if self[key] == value
    end
    return nil
  end

  def index_of_value (value)
    position(value)
  end
end

