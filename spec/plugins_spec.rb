#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Ircbot::Plugins do
  provide :client
  provide :plugins
  provide :[]
  provide :<<

  ######################################################################
  ### Enumerable

  provide :each
  it "should be enumerable" do
    subject.class.ancestors.should include(Enumerable)
  end
end
