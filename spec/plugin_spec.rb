#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

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

  provide :message
  its(:message) { should be_kind_of(Ircbot::Plugin::InitialMessage) }

  provide :plugins
  provide :running
  provide :config
  provide :client
  provide :bot

  ######################################################################
  ### private methods

  provide :plugin
  provide :plugin!
  provide :direct?

  ######################################################################
  ### Not connected

  context "(not connected)" do
    subject{ Ircbot::Plugin.new }

    its(:plugin , :foo) { should be_kind_of(Ircbot::Plugin::Null) }
    its(:plugin!, :foo) { lambda {subject}.should raise_error(Ircbot::PluginNotFound) }
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

