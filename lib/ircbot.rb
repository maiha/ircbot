require 'nkf'
require 'pathname'
require 'rubygems'
require 'extlib'
require 'extlib/dictionary'

######################################################################
### Load path

Thread.abort_on_exception = true
__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require "ircbot/framework"
require "ircbot/version"

Ircbot.push_path(:plugin, Ircbot.system_root + 'plugins')
Ircbot.toplevel_binding = binding

######################################################################
### IRC library

require "net/irc"

######################################################################
### Core ext

require "ircbot/core_ext/delegation" # from activesupport-2.3.5
require "ircbot/core_ext/extending"  # from activesupport-2.3.5
require "ircbot/core_ext/message"

######################################################################
### Ircbot 

require "ircbot/client"
