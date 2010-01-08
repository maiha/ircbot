
require 'spec'
require 'rr'

require File.join(File.dirname(__FILE__), '/../lib/ircbot')
require File.join(File.dirname(__FILE__), '/provide_helper')

def data(key)
  path = File.join(File.dirname(__FILE__) + "/fixtures/#{key}")
  File.read(path){}
end
