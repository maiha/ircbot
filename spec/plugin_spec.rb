#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

module Spec
  module Example
    module Subject
      module ExampleGroupMethods
        def its(*args, &block)
          describe(args.first) do
            define_method(:subject) { super().send(*args) }
            it(&block)
          end
        end
      end
    end
  end
end

describe Ircbot::Plugin do
  class Foo       < Ircbot::Plugin; end
  class Bar       < Ircbot::Plugin; end
  class BarPlugin < Ircbot::Plugin; end

  subject { Ircbot::Plugin.new }

  ######################################################################
  ### plugin name

  provide :plugin_name

  its(:plugin_name) { should == 'plugin' }
  describe "#plugin_name" do
    it { Foo.new.plugin_name.should == "foo" }
    it { Bar.new.plugin_name.should == "bar" }
    it { BarPlugin.new.plugin_name.should == "bar" }
  end

  ######################################################################
  ### private methods

  provide :plugin
  provide :plugin!
  provide :plugins
  provide :direct?


  ######################################################################
  ### Not connected

  context "(not connected)" do
    subject{ Ircbot::Plugin.new }

    its(:plugin , :foo) { should be_kind_of(Ircbot::Plugin::Null) }
    its(:plugin!, :foo) { lambda {subject}.should raise_error(Ircbot::Plugin::NotConnected) }
    its(:direct?      ) { should == false }
  end

  ######################################################################
  ### Connected

  describe "(connected)" do    
    before do
      @client  = Ircbot::Client.new({})
      @plugins = Ircbot::Plugins.new(@client)
      @foo     = Foo.new
      @bar     = Bar.new
      @plugins << @foo << @bar
    end
    subject{ Ircbot::Plugin.new(@plugins) }

    its(:plugin , :foo) { should == @foo }
    its(:plugin!, :foo) { should == @foo }
    its(:direct?      ) { should == false }
  end

end

