#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'ircbot'
require 'chawan'

class WhichPlugin < Ircbot::Plugin
  def reply(text)
    case text
    when /どっち.*(？|\?)/
      nouns = Chawan.parse($`).compact.noun
      noun = nouns[rand(nouns.size)]
      return "#{noun}に大決定や！"
    else
      return nil
    end
  rescue Chawan::CannotAnalyze
    return nil
  end
end

if $0 == __FILE__
  plugin = WhichPlugin.new
  puts plugin.reply("AKBとハロはどっちがいい？")
  puts plugin.reply("どっち？")
end
