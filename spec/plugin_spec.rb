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
  provide :nick

  ######################################################################
  ### Not connected

  context "(not connected)" do
    subject{ Ircbot::Plugin.new }

    it "#plugin(:foo) should detect Null plugin" do
      subject.send(:plugin, :foo).should be_kind_of(Ircbot::Plugin::Null)
    end

    it "#plugin!(:foo) should raise PluginNotFound" do
      lambda {
        subject.send(:plugin!, :foo)
      }.should raise_error(Ircbot::PluginNotFound)
    end

#    its(:direct?      ) { should == false }
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

    it "#plugin(:foo) should find the defined foo plugin" do
      subject.send(:plugin, :foo).should == @foo
    end

    it "#plugin!(:foo) should find the defined foo plugin" do
      subject.send(:plugin!, :foo).should == @foo
    end

#    its(:direct?      ) { should == false }
  end

end

