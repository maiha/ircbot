require File.join(File.dirname(__FILE__), "spec_helper")

describe Engines, "Engines with default settings" do
  before { Engines.setup }

  summary "http://www.asahi.com" do
    its(:class) {should == Engines::None}
  end
end

describe Engines, "Engines(http)" do
  before { Engines.setup("http") }

  summary "http://www.asahi.com" do
    its(:class) {should == Engines::Http}
  end
end

describe Engines, "Engines(https,twitter,ch2)" do
  before { Engines.setup(["https", "twitter", "ch2"]) }

  summary "https://example.com" do
    its(:class) {should == Engines::Https}
  end

  summary "https://twitter.com" do
    its(:class) {should == Engines::Twitter}
  end

  summary "http://hayabusa3.2ch.net/test/read.cgi/morningcoffee/1333357582/" do
    its(:class) {should == Engines::Ch2}
  end

  summary "http://www.asahi.com" do
    its(:class) {should == Engines::None}
  end

  summary "" do
    its(:class) {should == Engines::None}
  end
end
