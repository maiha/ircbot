#!/usr/bin/env ruby -Ku
# -*- coding: utf-8 -*-

######################################################################
# [Install]
#
# gem install chawan dm-core dm-migrations dm-timestamps do_sqlite3 data_objects
#

require 'rubygems'
require 'ircbot'
require 'chawan'
require 'night-time'

require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

class Time
  def midnight?
    hour == 0 and min == 0 and sec == 0
  end

  def just?
    min == 0 and sec == 0
  end
end

module Reminder
  def self.connect(path = nil)
    @connecteds ||= {}
    @connecteds[path] ||=
      (
       path = Pathname(path || Ircbot.root + "db" + "reminder.db").expand_path
       path.parent.mkpath
       DataMapper.setup(:default, "sqlite3://#{path}")
       Reminder::Event.auto_upgrade!
       )
  end

  class EventNotFound < RuntimeError; end
  class EventNotSaved < RuntimeError
    attr_accessor :event
    def initialize(event)
      @event = event
    end
  end
  class EventHasDone  < EventNotSaved; end
  class StartNotFound < EventNotSaved; end

  class Event
    include DataMapper::Resource

    class << self
      def default_storage_name
        "event"
      end

      def reminders
        all(:alerted=>false, :alert_at.lt=>Time.now, :order=>[:alert_at])
      end
    end

    property :id       , Serial
    property :st       , DateTime                   # 開始日時
    property :en       , DateTime                   # 終了日時
    property :title    , String                     # 件名
    property :desc     , String                     # 詳細
    property :where    , String                     # 場所
    property :allday   , Boolean , :default=>false  # 終日フラグ
    property :alert_at , DateTime                   # お知らせ日時
    property :alerted  , Boolean , :default=>false  # お知らせ済

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
      connect
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
          events = Reminder::Event.reminders
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

  def reply(text)
    start_reminder

    case text
    when %r{^\d{4}.?\d{1,2}.?\d{1,2}}
      event = Reminder.register(text)
      return "Remind you again at %s" % event.alert_at.strftime("%Y-%m-%d %H:%M")
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
    def start_reminder(&callback)
      bot = self.bot
      callback ||= proc{|event| bot.broadcast event.to_s}
      @event_watcher_thread ||=
        (Reminder.connect
         reminder = EventWatcher.new(:interval=>60, :callback=>callback)
         Thread.new { reminder.start })
    end
end


######################################################################
### Setup database

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
    system("spec -cfs #{tmp.path}")
  end
end

__END__

require 'spec'
require 'ostruct'

module Spec
  module Example
    module Subject
      module ExampleGroupMethods
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
end
