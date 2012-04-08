#!/usr/bin/env ruby -Ku
# -*- coding: utf-8 -*-

######################################################################
# [Install]
#
# gem install chawan night-time dm-core dm-migrations dm-timestamps do_sqlite3 data_objects dm-sqlite-adapter -V
#

require 'rubygems'
require 'ircbot'
require 'chawan'
require 'night-time'

require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

module Reminder
  def self.connect(path = nil)
    @connecteds ||= {}
    @connecteds[path] ||=
      (
       path ||= Pathname(Dir.getwd) + "db" + "reminder.db"
       path = Pathname(path).expand_path
       path.parent.mkpath
       DataMapper.setup(:default, "sqlite3://#{path}")
       Reminder::Event.auto_upgrade!
       )
  end

  ######################################################################
  ### Exceptions

  class EventNotFound < RuntimeError; end
  class EventNotSaved < RuntimeError
    attr_accessor :event
    def initialize(event)
      @event = event
    end
  end
  class EventHasDone  < EventNotSaved; end
  class StartNotFound < EventNotSaved; end

  ######################################################################
  ### Event

  class Event
    include DataMapper::Resource

    property :id       , Serial
    property :st       , DateTime                   # 開始日時
    property :en       , DateTime                   # 終了日時
    property :title    , String                     # 件名
    property :desc     , String                     # 詳細
    property :where    , String                     # 場所
    property :allday   , Boolean , :default=>false  # 終日フラグ
    property :alerted  , Boolean , :default=>false  # お知らせ済
    property :alert_at , DateTime                   # お知らせ日時

    ######################################################################
    ### Class methods

    class << self
      def default_storage_name
        "event"
      end

      def alerts
        all(:alerted=>false, :alert_at.lt=>Time.now, :order=>[:alert_at])
      end

      def future
        all(:alerted=>false, :alert_at.gt=>Time.now, :order=>[:alert_at])
      end
    end

    ######################################################################
    ### Instance methods

    def done!
      self.alerted = true
      save
    end

    def to_s
      desc.to_s
    end
  end

  module TimeParser
    def parse(text)
      event = Event.new
      event.desc   = text
      event.title  = text.sub(%r{^[\s\d:-]+}, '')
      event.allday = false

      t = Date._parse(text)
      # => {:zone=>"-14:55", :year=>2010, :hour=>13, :min=>30, :mday=>4, :offset=>-53700, :mon=>1}

      if t[:year] && t[:mon] && t[:mday] && t[:hour]
        event.st = Time.mktime(t[:year], t[:mon], t[:mday], t[:hour], t[:min], t[:sec])
        if t[:zone].to_s =~ /^-?(\d+):(\d+)(:(\d+))?$/
          event.en = Time.mktime(t[:year], t[:mon], t[:mday], $1, $2, $4)
        end
      else
        event.allday = true
        event.st     = Time.mktime(t[:year], t[:mon], t[:mday]) rescue nil
      end

      return event
    end

    def register(text)
      event = parse(text)
      event.st or raise StartNotFound, event
      if event.st.to_time > Time.now
        event.alert_at = Time.at(event.st.to_time.to_i - 30*60)
        event.save or raise EventNotSaved, event
        return event
      else
        raise EventHasDone, event
      end
    end
  end

  extend TimeParser
end


class ReminderPlugin < Ircbot::Plugin
  class EventWatcher
    attr_accessor :interval
    attr_accessor :callback

    def initialize(options = {})
      @interval = options[:interval] || 60
      @callback = options[:callback] || proc{|e| puts e}
    end

    def start
      loop do
        if callback
          events = Reminder::Event.alerts
          #debug "#{self.class} found #{events.size} events"
          events.each do |event|
            callback.call(event)
            event.done!
          end
        end
        sleep interval
      end
    end
  end

  def help
    ["list -> show future reminders",
     "YYYY-mm-dd or YYYY-mm-dd HH:MM text -> register the text"].join("\n")
  end

  def setup
    bot = self.bot
    callback = proc{|event| bot.broadcast event.to_s}
    @event_watcher_thread ||=
      (connect
       reminder = EventWatcher.new(:interval=>60, :callback=>callback)
       Thread.new { reminder.start })
  end

  def list
    events = Reminder::Event.future
    if events.size == 0
      return "no reminders"
    else
      lead = "#{events.size} reminder(s)"
      body = events.map(&:to_s)[0,5]
      return ([lead] + body).join("\n")
    end
  end

  def reply(text)
    # strip noise
    text = text.sub(/^<.*?>/,'').strip

    case text
    when %r{^\d{4}.?\d{1,2}.?\d{1,2}}
      event = Reminder.register(text)
      text  = "Remind you again at %s" % event.alert_at.strftime("%Y-%m-%d %H:%M")
      return text
    end
    return nil

  rescue Reminder::EventNotFound
    return nil

  rescue Reminder::StartNotFound => e
    return "Reminder cannot detect start: #{e.event.st}"

  rescue Reminder::EventHasDone => e
    puts "Reminder ignores past event: #{e.event.st}"
    return nil
  end

  private
    def reminder_db_path
      Ircbot.root + "db" + "reminder-#{config.nick}.db"
    end

    def connect
      @connect ||= Reminder.connect(reminder_db_path)
    end
end


######################################################################
### Spec in file:
###   ruby plugins/reminder.rb

if $0 == __FILE__

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
      def parse(text, &block)
        describe "(#{text})" do
          subject {
            event = Reminder.parse(text)
            hash  = {
              :st     => (event.st.strftime("%Y-%m-%d %H:%M:%S") rescue nil),
              :en     => (event.en.strftime("%Y-%m-%d %H:%M:%S") rescue nil),
              :title  => event.title.to_s,
              :desc   => event.title.to_s,
              :allday => event.allday,
            }
            OpenStruct.new(hash)
          }
          instance_eval(&block)
        end
      end
    end
  end
end

describe "Reminder#parse" do

  parse '' do
    its(:st)     { should == nil }
  end

  parse '2010-01-04 CX' do
    its(:st)     { should == "2010-01-04 00:00:00" }
    its(:en)     { should == nil }
    its(:title)  { should == "CX" }
    its(:allday) { should == true }
  end

  parse '2010-01-04 13:30 CX' do
    its(:st)     { should == "2010-01-04 13:30:00" }
    its(:en)     { should == nil }
    its(:title)  { should == "CX" }
    its(:allday) { should == false }
  end

  parse '2010-01-04 13:30-14:55 CX' do
    its(:st)     { should == "2010-01-04 13:30:00" }
    its(:en)     { should == "2010-01-04 14:55:00" }
    its(:title)  { should == "CX" }
    its(:allday) { should == false }
  end

  parse '2010-01-18 27:15-27:45 TX' do
    its(:st)     { should == "2010-01-19 03:15:00" }
    its(:en)     { should == "2010-01-19 03:45:00" }
    its(:title)  { should == "TX" }
    its(:allday) { should == false }
  end
end
