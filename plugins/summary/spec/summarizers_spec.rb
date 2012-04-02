require File.join(File.dirname(__FILE__), "spec_helper")

require 'summarizers'

describe Summarizers do
  summary "https://example.com" do
    its(:class) {should == Summarizers::Https}
  end

  summary "https://twitter.com" do
    its(:class) {should == Summarizers::Twitter}
  end

  summary "http://hayabusa3.2ch.net/test/read.cgi/morningcoffee/1333357582/" do
    its(:class) {should == Summarizers::Ch2}
  end

  summary "http://www.asahi.com" do
    its(:class) {should == Summarizers::None}
  end

  summary "" do
    its(:class) {should == Summarizers::None}
  end
end
