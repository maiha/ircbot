#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

module TestHtmlParserGetTitle
  def get_title(html, title)
    describe "(#{html})" do
      subject { Object.new.extend Ircbot::Utils::HtmlParser }
      it "should return #{title}" do
        subject.get_title(html).should == title
      end
    end
  end
end

describe Ircbot::Utils::HtmlParser do
  subject { Object.new.extend Ircbot::Utils::HtmlParser }

  ######################################################################
  ### accessor methods

  provide :get_title

  describe "#get_title" do
    extend TestHtmlParserGetTitle
    get_title "xxx", ""
    get_title "xxx<title>yyy</title>zzz", "yyy"
    get_title "xxx<title><a>yyy</a></title>zzz", "yyy"
  end
end
