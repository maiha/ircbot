require File.join(File.dirname(__FILE__), "spec_helper")

require 'ch2'
require 'ostruct'

module RSpec
  module Core
    module SharedExampleGroup
      def ch2(url, &block)
        describe "(#{url})" do
          subject { Ch2::Dat.new(url) }
          instance_eval(&block)
        end
      end
    end
  end
end

describe "Ch2::Dat" do
  ch2 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == nil }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  ch2 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/430' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "430" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  ch2 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/n' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "n" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  ch2 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/5-10' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "5-10" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  ch2 'http://google.com' do
    its(:host)     { should == "google.com" }
    its(:board)    { should == nil }
    its(:num)      { should == nil }
    its(:arg)      { should == nil }
    its(:valid?)   { should == false }
  end
end

