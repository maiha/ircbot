require 'nkf'
require 'pathname'
require 'rubygems'

######################################################################
### Load path

Thread.abort_on_exception = true
__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require "ircbot/framework"

######################################################################
### IRC library

require "net/irc"

######################################################################
### Core ext

require "ircbot/core_ext/message"

######################################################################
### Ircbot 

require "ircbot/client"
