#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Ircbot::Plugins do

  ######################################################################
  ### accessor methods

  provide :client
  provide :plugins
  provide :active
  provide :load
  provide :plugin!
  provide :plugin
  provide :[]
  provide :<<
  provide :bot
  provide :start
  provide :stop
  provide :delete

  ######################################################################
  ### Enumerable

  provide :each
  it "should be enumerable" do
    subject.class.ancestors.should include(Enumerable)
  end

end
