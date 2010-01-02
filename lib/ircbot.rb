
require 'nkf'

######################################################################
### Load path

Thread.abort_on_exception = true
__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'ircbot/framework'


######################################################################
### IRC library

require 'irc/irc'
require 'irc/agent'
require 'irc/client'


######################################################################
### Ircbot library

require 'ircbot/core_ext/rand-polimorphism'
require 'ircbot/core_ext/writefile'
require 'ircbot/core_ext/digest'
require 'ircbot/core_ext/irc'


######################################################################
### Ircbot 

require 'ircbot/reply_client'

