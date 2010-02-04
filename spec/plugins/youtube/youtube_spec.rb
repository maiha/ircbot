#!/usr/bin/ruby

require File.join(File.dirname(__FILE__), '../../spec_helper')
require File.join(File.dirname(__FILE__), '../../../plugins/youtube')

describe YouTubeContentParser do
  def read_html
    File.read(File.join(File.dirname(__FILE__), 'watch.html')){}
  end

  subject { YouTubeContentParser.new(read_html) }

  its(:t        ) { should == "vjVQa1PpcFMM99xF5DDdn1Y5rGqcnQn41lknwX12zRg%3D" }
  its(:video_id ) { should == "8dtKt4A7SzI" }
  its(:get_video) { should == "http://youtube.com/get_video.php?t=vjVQa1PpcFMM99xF5DDdn1Y5rGqcnQn41lknwX12zRg%3D&video_id=8dtKt4A7SzI&fmt=18" }
end


