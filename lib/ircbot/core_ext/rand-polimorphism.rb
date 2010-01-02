#!/usr/local/bin/ruby
#
# rand-extension.rb
# Author:  
# Created: Thu Nov  8 17:26:09 2001


# rand の多様性
unless $__RAND_OVERRIDE__
  $__RAND_OVERRIDE__ = true
  alias :__rand__ :rand 
  def rand (obj)
    case obj
    when Array
      index = __rand__(obj .size)
      obj[index]
    when Range
      rand(obj .to_a)
    else
      __rand__(obj)
    end
  end
end
