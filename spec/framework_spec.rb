#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Ircbot do
  provide :root
  provide :root=
  provide :push_path
  provide :glob_for

  describe ".glob_for" do
    it do
      dir = Pathname(File.dirname(__FILE__))
      Ircbot.push_path(:spec, dir)
      Ircbot.glob_for(:spec, "sama-zu").should == [dir + "fixtures" + "sama-zu.yml"]
    end
  end
end
