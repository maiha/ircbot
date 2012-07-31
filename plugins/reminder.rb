#!/usr/bin/env ruby -Ku
# -*- coding: utf-8 -*-

require 'rubygems'
require 'ircbot'
require 'night-time'

require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

module Reminder
  REPOSITORY_NAME = :reminder

  def self.connect(uri)
    DataMapper.setup(REPOSITORY_NAME, uri)
    Reminder::Event.auto_upgrade!
  end

  ######################################################################
  ### Exceptions

  class EventNotFound < RuntimeError; end
  class EventFound    < RuntimeError
    attr_accessor :event
    def initialize(event)
      @event = event
    end
  end
  class EventNotSaved < EventFound   ; end
  class EventHasDone  < EventNotSaved; end
  class StartNotFound < EventNotSaved; end

  ######################################################################
  ### Event

  class Event
    def self.default_repository_name; REPOSITORY_NAME; end
    def self.default_storage_name   ; "event"; end

    include DataMapper::Resource

    property :id       , Serial
    property :st       , DateTime                   # 開始日時
    property :en       , DateTime                   # 終了日時
    property :title    , String, :length=>255       # 件名
    property :desc     , Text                       # 詳細
    property :where    , String, :length=>255       # 場所
    property :source   , String, :length=>255       # 情報ソース
    property :allday   , Boolean , :default=>false  # 終日フラグ
    property :alerted  , Boolean , :default=>false  # お知らせ済
    property :alert_at , DateTime                   # お知らせ日時

    ######################################################################
    ### Class methods

    class << self
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

  def self.parse!(text)
    case text
    when /^\s*>>/
      # 引用は無視
      raise EventNotFound

    else
      # 先頭40bytesに時刻ぽい文字列があれば登録とみなす
      jst    = NightTime::Jst.new(text[0,40])
      array  = jst.parse

      # 日付なし
      array[1] && array[2] or raise EventNotFound

      event = Event.new
      event.desc   = text
      event.title  = text.sub(%r{^[\s\d:-]+}, '')
      event.allday = array[3].nil?
      event.st     = jst.time

      return event
    end
  end

  module Registable
    def register(event)
      event.st or raise StartNotFound, event
      if event.st.to_time > Time.now
        event.source   = "irc/reminder"
        event.alert_at = Time.at(event.st.to_time.to_i - 30*60)
        event.save or raise EventNotSaved, event
        return event
      else
        raise EventHasDone, event
      end
    end
  end

  extend Registable
end


class ReminderPlugin < Ircbot::Plugin
  DEFAULT_REMIND_MSG = "Remind you again at %s"

  class EventWatcher < Ircbot::Utils::Watcher
    def srcs
      Reminder::Event.alerts
    end
  end

  def setup
    return if @watcher
    bot = self.bot

    uri = self[:db]
    unless uri
      path = Ircbot.root + "db" + "#{config.nick}-reminder.db"
      uri  = "sqlite3://#{path}"
      path.parent.mkpath
    end

    Reminder.connect(uri)
    callback = proc{|event| bot.broadcast event.to_s; event.done!}
    reminder = EventWatcher.new(:interval=>60, :callback=>callback)
    @watcher = Thread.new { reminder.start }
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
   
    event = Reminder.parse!(text)
    Reminder.register(event)

    return accepted_message(event)

  rescue Reminder::EventNotFound
    return nil

  rescue Reminder::StartNotFound => e
    # return "Reminder cannot detect start: #{e.event.st}"
    return nil

  rescue Reminder::EventHasDone => e
    puts "Reminder ignores past event: #{e.event.st}"
    return nil
  end

  private
    def accepted_message(event)
      fmt  = self[:accept_fmt] || DEFAULT_REMIND_MSG
      text = fmt % event.alert_at.strftime("%Y-%m-%d %H:%M")

      if text.blank?
        return nil
      else
        return text
      end
    end
end

