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

  ######################################################################
  ### Initializer

  describe ".new" do
    let(:client)  { nil }
    let(:args)    { [] }

    it "should accept plugin names(Array)" do
      plugins = Ircbot::Plugins.new(client, ["summary", "reminder"])
      plugins.active_names.should == ["summary", "reminder"]
    end

    it "should accept plugin attrs(Array(Hash))" do
      args = [
        {"name"=>"summary", "db"=>"sqlite:db.sqlite"},
        {"name"=>"reminder"},
      ]
      plugins = Ircbot::Plugins.new(client, args)
      plugins.active_names.should == ["summary", "reminder"]

      plugins["summary"]["db"].should == "sqlite:db.sqlite"
    end

    it "should ignore when plugin name is not set in attrs" do
      args = [
        {"db"=>"sqlite:db.sqlite"},
        {"name"=>"reminder"},
      ]
      plugins = Ircbot::Plugins.new(client)
      plugins.should_receive(:invalid_plugin_found)
      plugins.load(args)

      plugins.active_names.should == ["reminder"]
    end
  end
end
