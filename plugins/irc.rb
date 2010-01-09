#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'

class IrcPlugin < Ircbot::Plugin
  def reply(text)
    if direct?
      if text[0] == ?!
        command, params = text[1..-1].strip.split(/\s+/,2)
        command = Net::IRC::Constants.const_get(command.to_s.upcase)
        bot.__send__(:post, command, params)
        throw :halt
      end
    end
    return nil
  end
end

