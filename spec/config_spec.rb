#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Ircbot::Client do
  it "should provide .new" do
    Ircbot::Client.should respond_to(:new)
  end

  describe ".new" do
    it "should accept a hash" do
      lambda { 
        Ircbot::Client.new({})
      }.should_not raise_error
    end
  end

  describe "#config" do
    before do
      @config = {
        :nick => "sama-zu",
        :user => "samazu",
        :real => "sama~zu",
        :host => "localhost",
        :port => "6667",
      }
    end

    subject { Ircbot::Client.new(@config).config }

    its(:nick) { should == "sama-zu" }
    its(:user) { should == "samazu" }
    its(:real) { should == "sama~zu" }
    its(:host) { should == "localhost" }
    its(:port) { should == "6667" }

    describe "#channels" do
      it "should return the array when an array is given" do
        @config[:channels] = ["#ircbot"]
        subject.channels.should == ["#ircbot"]
      end

      it "should return array when a string is given" do
        @config[:channels] = "#ircbot"
        subject.channels.should == ["#ircbot"]
      end

      it "should return [] when nil" do
        @config[:channels] = nil
        subject.channels.should == []
      end
    end
  end

  ######################################################################
  ### Initialize from file

  it "should provide .from_file" do
    Ircbot::Client.should respond_to(:from_file)
  end

  ######################################################################
  ### Readers

  describe Ircbot::Client::Config do
    describe "#read" do
      it "should delegate to read_yml" do
#         mock(subject).read_yml(__FILE__)
#         subject.read(__FILE__)
      end
    end

    describe "#read_yml" do
      it do
        hash = Ircbot::Client::Config.read(path("sama-zu.yml"))
        hash.should be_a_kind_of(Mash)
        hash["nick"].should == "sama-zu"
        hash[:nick].should == "sama-zu"
      end
    end
  end

end
