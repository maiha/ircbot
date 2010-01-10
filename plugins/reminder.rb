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
require 'parsedate'

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
    path = Pathname(path || Ircbot.root + "db" + "reminder.db").expand_path
    path.parent.mkpath
    DataMapper.setup(:default, "sqlite3://#{path}")
    Reminder::Event.auto_upgrade!
  end

  class EventNotFound < RuntimeError; end

  class Event
    include DataMapper::Resource

    def self.default_storage_name
      "event"
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
  end

  module TimeParser
    def normalize(hour, min, sec)
      extra = 0
      hour ||= 0
      min  ||= 0
      sec  ||= 0

      squeeze = lambda{|val, max, unit, extra|
        num, new_val = val.divmod(max)
        [new_val, extra + max*num*unit]
      }

      sec , extra = squeeze.call(sec , 60, 1    , extra)
      min , extra = squeeze.call(min , 60, 60   , extra)
      hour, extra = squeeze.call(hour, 24, 60*60, extra)

      return [hour, min, sec, extra]
    end

    def parse(text)
      event = Event.new
      event.desc   = text
      event.title  = text.sub(%r{^[\s\d:-]+}, '')
      event.allday = false

      array = ParseDate.parsedate(text)
      year  = array[0].to_i
      mon   = array[1].to_i
      day   = array[2].to_i
      hour  = array[3]
      min   = array[4]
      sec   = array[5]
      tzone = array[6].to_s

      if hour
        array = normalize(hour, min, sec)
        event.st = Time.mktime(year, mon, day, *array[0,3]) + array.last

        if tzone =~ /^-?(\d+):(\d+)(:(\d+))?$/
          array = normalize($1.to_i,$2.to_i,$4.to_i)
          event.en = Time.mktime(year, mon, day, *array[0,3]) + array.last
        end
      else
        event.allday = true
        event.st     = Time.mktime(year,mon,day)
      end

      return event

    rescue Exception => e
      raise EventNotFound, e.to_s
    end
  end

  extend TimeParser
end


class ReminderPlugin < Ircbot::Plugin
  class EventWatcher
    def initialize(options = {})
      @interval = options[:interval] || 60
      @calback  = options[:callback]
    end

    def start
      loop do
        if @callback
          events = Reminder::Event.all(:alerted=>false, :alert_at.lt=>Time.now, :order=>[:alert_at])
          debug "#{self.class} found #{events.size} events"
          events.each do |event|
            @callback.call(event)
            event.done!
          end
        end
        sleep @interval
      end
    end
  end

  def reply(text)
    ensure_connection
    start_event_watcher

    case text
    when %r{^\d{4}.?\d{1,2}.?\d{1,2}}
      event = Reminder.parse(text)
      if event.st.to_time > Time.now
        event.alert_at = Time.at(event.st.to_time.to_i - 30*60)
        event.save or raise "CannotSaveEvent"
        return "Remind you again at %s" % event.alert_at.strftime("%Y-%m-%d %H:%M")
      else
        debug "Reminder ignores past event: #{event.st}"
      end
    end

    return nil

  rescue Reminder::EventNotFound
    return nil
  end

  private
    def ensure_connection
      @ensure_connection ||= Reminder.connect
    end

    def start_event_watcher
      unless @event_watcher_thread
        broadcast = proc{|event|
          bot.broadcast event.desc
        }
        @event_watcher = EventWatcher.new(:interval=>60, :callback=>broadcast)
        @event_watcher_thread = Thread.new {
          @event_watcher.start
        }
      end
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
