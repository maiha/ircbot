
require 'spec'
require 'rr'

require File.join(File.dirname(__FILE__), '/../lib/ircbot')
require File.join(File.dirname(__FILE__), '/provide_helper')


def path(key)
  Pathname(File.join(File.dirname(__FILE__) + "/fixtures/#{key}"))
end

def data(key)
  path(key).read{}
end
