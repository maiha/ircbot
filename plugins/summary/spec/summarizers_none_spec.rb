require File.join(File.dirname(__FILE__), "spec_helper")

require 'summarizers'

describe Summarizers::None do
  subject { Summarizers::None.new('') }

  describe "#execute" do
    it "should raise Nop" do
      lambda {
        subject.execute
      }.should raise_error(Summarizers::Nop)
    end
  end
end
