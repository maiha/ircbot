#!/usr/bin/env ruby -Ku
# -*- coding: utf-8 -*-

######################################################################
# [Install]
#
# gem install chawan night-time dm-core dm-migrations dm-timestamps do_sqlite3 data_objects dm-sqlite-adapter -V
#

require 'rubygems'
require 'ircbot'
require 'uri'

require 'watchdog/exceptions'
require 'watchdog/db'
require 'watchdog/updater'

class WatchdogPlugin < Ircbot::Plugin
  INTERVAL = 600                # re-fetch urls after this sec

  def help
    ["#{config.nick}.watchdog.list",
     "#{config.nick}.watchdog.add <URL>",
     "#{config.nick}.watchdog.del <URL>",
    ].join("\n")
  end

  def setup
    return if @watcher
    bot = self.bot
    Watchdog.connect(Ircbot.root + "db" + "#{config.nick}-watchdog.db")
    callback = proc{|page| bot.broadcast "Updated: #{page}"; page.done! }
    updater  = Watchdog::Updater.new(:interval => INTERVAL, :callback => callback)
    @watcher = updater.start
  end

  def add(text)
    count = 0
    urls = URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}
    urls.each do |url|
      next if Watchdog::Page.first(:url=>url)
      page = Watchdog::Page.create!(:url=>url)
      page.update!
      count += 1
    end
    return "Added #{count} urls"
  end

  def del(text)
    count = 0
    urls = URI.extract(text).map{|i| i.sub(/^ttp:/, 'http:')}
    urls.each do |url|
      page = Watchdog::Page.first(:url=>url)
      if page
        page.destroy
        count += 1
      end
    end
    return "Deleted #{count} urls"
  end

  def list
    pages = Watchdog::Page.all
    if pages.size == 0
      return "no watchdogs"
    else
      lead = "#{pages.size} watchdog(s)"
      body = pages.map(&:to_s)[0,5]
      return ([lead] + body).join("\n")
    end
  end
end

