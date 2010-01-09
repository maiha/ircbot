#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'

class EchoPlugin < Ircbot::Plugin
  def help
    "[Echo] echo back privmsg"
  end

  def reply(text)
    return "[#{text}]"
  end
end
