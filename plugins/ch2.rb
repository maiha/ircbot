#!/usr/bin/env ruby
# vim:encoding=UTF-8:

# original: net-irc-0.0.9/examples/2ch.rb

$KCODE = "u" if RUBY_VERSION < "1.9" # json use this

require 'rubygems'
require 'uri'
require 'net/http'
require 'stringio'
require 'zlib'
require 'nkf'
require 'ircbot'

module Ch2
  class Dat
    class UnknownThread < StandardError; end

    attr_accessor :uri
    attr_accessor :last_modified, :size

    Line = Struct.new(:n, :name, :mail, :misc, :body, :opts, :id) do
      def to_s
        [name, body, misc, opts].compact.join(" ")
      end

      def <=>(other)
        body.to_s.size <=> other.body.to_s.size
      end

      def aa?
        body = self.body
        return false if body.count("\n") < 3

        significants = body.scan(/[>\n0-9a-z０-９A-Zａ-ｚＡ-Ｚぁ-んァ-ン一-龠]/u).size.to_f
        body_length  = body.scan(/./u).size
        is_aa = 1 - significants / body_length

        is_aa > 0.6
      end
    end

    attr_reader :board, :num, :arg
    delegate :host, :port, :to => "@uri"

    def initialize(thread_uri)
      @uri = URI(thread_uri)
      _, _, _, @board, @num, = *@uri.path.split('/')
      @dat = []

      case @uri.path
      when %r{^/test/read\.cgi/(.*?)/(\d+)(/(.+))?}
        @arg = $4
      end
      @valid = !! (@board && @num)
    end

    def valid?
      @valid
    end

    def length
      @dat.length
    end

    def subject
      retrieve(true) if @dat.size.zero?
      self[1].opts || ""
    end

    def [](n)
      l = @dat[n - 1]
      return nil unless l
      name, mail, misc, body, opts = * l.split(/<>/)
      id = misc[/ID:([^\s]+)/, 1]

      body.gsub!(/<br>/, "\n")
      body.gsub!(/<[^>]+>/, "")
      body.gsub!(/^\s+|\s+$/, "")
      body.gsub!(/&(gt|lt|amp|nbsp);/) {|s|
        { 'gt' => ">", 'lt' => "<", 'amp' => "&", 'nbsp' => " " }[$1]
      }

      Line.new(n, name, mail, misc, body, opts, id)
    end

    def dat
      @num
    end

    def retrieve(force=false)
      @dat = [] if @force

      res = Net::HTTP.start(@uri.host, @uri.port) do |http|
        req = Net::HTTP::Get.new('/%s/dat/%d.dat' % [@board, @num])
        req['User-Agent']        = 'Monazilla/1.00 (2ig.rb/0.0e)'
        req['Accept-Encoding']   = 'gzip' unless @size
        unless force
          req['If-Modified-Since'] = @last_modified if @last_modified
          req['Range']             = "bytes=%d-" % @size if @size
        end

        http.request(req)
      end

      ret = nil
      case res.code.to_i
      when 200, 206
        body = res.body
        if res['Content-Encoding'] == 'gzip'
          body = StringIO.open(body, 'rb') {|io| Zlib::GzipReader.new(io).read }
        end

        @last_modified = res['Last-Modified']
        if res.code == '206'
          @size += body.size
        else
          @size  = body.size
        end

        body = NKF.nkf('-w', body)

        curr = @dat.size + 1
        @dat.concat(body.split(/\n/))
        last = @dat.size

        (curr..last).map {|n|
          self[n]
        }
      when 416 # たぶん削除が発生
        p ['416']
        retrieve(true)
        []
      when 304 # Not modified
        []
      when 302 # dat 落ち
        p ['302', res['Location']]
        raise UnknownThread
      else
        p ['Unknown Status:', res.code]
        []
      end
    end

    def canonicalize_subject(subject)
      subject.gsub(/[Ａ-Ｚａ-ｚ０-９]/u) {|c|
        c.unpack("U*").map {|i| i - 65248 }.pack("U*")
      }
    end

    def guess_next_thread
      res = Net::HTTP.start(@uri.host, @uri.port) do |http|
        req = Net::HTTP::Get.new('/%s/subject.txt' % @board)
        req['User-Agent']        = 'Monazilla/1.00 (2ig.rb/0.0e)'
        http.request(req)
      end

      recent_posted_threads = (900..999).inject({}) {|r,i|
        line = self[i]
        line.body.scan(%r|ttp://#{@uri.host}/test/read.cgi/[^/]+/\d+/|).each do |uri|
          r["h#{uri}"] = i
        end if line
        r
      }

      current_subject    = canonicalize_subject(self.subject)
      current_thread_rev = current_subject.scan(/\d+/).map {|d| d.to_i }
      current            = current_subject.scan(/./u)

      body = NKF.nkf('-w', res.body)
      threads = body.split(/\n/).map {|l|
        dat, rest = *l.split(/<>/)
        dat.sub!(/\.dat$/, "")

        uri = "http://#{@uri.host}/test/read.cgi/#{@board}/#{dat}/"

        subject, n = */(.+?) \((\d+)\)/.match(rest).captures
        canonical_subject = canonicalize_subject(subject)
        thread_rev     = canonical_subject[/\d+/].to_i

        distance       = (dat     == self.dat)     ? Float::MAX :
        (subject == self.subject) ? 0 :
        levenshtein(canonical_subject.scan(/./u), current)
        continuous_num = current_thread_rev.find {|rev| rev == thread_rev - 1 }
        appear_recent  = recent_posted_threads[uri]

        score = distance
        score -= 10 if continuous_num
        score -= 10 if appear_recent
        score += 10 if dat.to_i < self.dat.to_i
        {
          :uri            => uri,
          :dat            => dat,
          :subject        => subject,
          :distance       => distance,
          :continuous_num => continuous_num,
          :appear_recent  => appear_recent,
          :score          => score.to_f
        }
      }.sort_by {|o|
        o[:score]
      }

      threads
    end

    def levenshtein(a, b)
      case
      when a.empty?
        b.length
      when b.empty?
        a.length
      when a == b
        0
      else
        d = Array.new(a.length + 1) { |s|
          Array.new(b.length + 1, 0)
        }

        (0..a.length).each do |i|
          d[i][0] = i
        end

        (0..b.length).each do |j|
          d[0][j] = j
        end

        (1..a.length).each do |i|
          (1..b.length).each do |j|
            cost = (a[i - 1] == b[j - 1]) ? 0 : 1
            d[i][j] = [
                       d[i-1][j  ] + 1,
                       d[i  ][j-1] + 1,
                       d[i-1][j-1] + cost
                      ].min
          end
        end

        d[a.length][b.length]
      end
    end

    def dat_url
      "http://%s/%s/dat/%d.dat" % [host, board, num]
    end

    def summarize
      retrieve
      case arg
      when /^\d+$/                # exact id
        range = (arg.to_i .. arg.to_i)
      when /^(\d+)-$/
        range = ($1.to_i .. 1000)
      when /^-(\d+)$/
        range = (1 .. $2.to_i)
      else
        range = (1 .. 1000)
      end

      lines = range.map{|i| self[i]}.compact
      if lines.size == 1
        return lines.first.to_s
      else
        return lines.map(&:body).sort_by(&:size).reverse.join(" ").gsub(/\s+/, ' ')
      end
    end
  end
end

######################################################################
### Spec in file:
###   ruby 2ch.rb

if $0 == __FILE__

  require 'pathname'
  require 'tempfile'

  def spec(src, buffer, &block)
    buffer = "require '#{Pathname(src).expand_path}'\n" + buffer
    tmp = Tempfile.new("dynamic-spec")
    tmp.print(buffer)
    tmp.close
    block.call(tmp)
  ensure
    tmp.close(true)
  end

  spec($0, DATA.read{}) do |tmp|
    system("rspec -cfs #{tmp.path}")
  end
end

__END__

require 'rspec'
require 'ostruct'

module RSpec
  module Core
    module SharedExampleGroup
      def parse(url, &block)
        describe "(#{url})" do
          subject {
            Ch2::Dat.new(url)
          }
          instance_eval(&block)
        end
      end
    end
  end
end

describe "Ch2::Dat" do
  parse 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == nil }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  parse 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/430' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "430" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  parse 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/n' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "n" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  parse 'http://news22.2ch.net/test/read.cgi/newsplus/1185716060/5-10' do
    its(:host)     { should == "news22.2ch.net" }
    its(:board)    { should == "newsplus" }
    its(:num)      { should == "1185716060" }
    its(:arg)      { should == "5-10" }
    its(:dat_url)  { should == "http://news22.2ch.net/newsplus/dat/1185716060.dat" }
    its(:valid?)   { should == true }
  end

  parse 'http://google.com' do
    its(:host)     { should == "google.com" }
    its(:board)    { should == nil }
    its(:num)      { should == nil }
    its(:arg)      { should == nil }
    its(:valid?)   { should == false }
  end
end
