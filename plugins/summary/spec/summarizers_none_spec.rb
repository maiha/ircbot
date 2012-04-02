require File.join(File.dirname(__FILE__), "spec_helper")

require 'engines'

describe Engines::None do
  subject { Engines::None.new('') }

  describe "#execute" do
    it "should raise Nop" do
      lambda {
        subject.execute
      }.should raise_error(Engines::Nop)
    end
  end
end
