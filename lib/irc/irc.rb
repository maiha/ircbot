=begin header
Internet Relay Chat Protocol Library -- Main Part

  $Author: knu $
  $Date: 2001/01/31 10:55:28 $

  Copyright (C) 1998-2000 Hiroshi IGARASHI
=end

require 'socket'
require 'thread'
require 'kconv'
require 'irc/localize'
require 'irc/const'

module IRC
  class Message
=begin
IRC messages in IRC protocol
=end
  
    include Constants

    attr_accessor(:prefix)
    attr_accessor(:command)
    attr_accessor(:params)
    attr_accessor(:trailing)
    attr_accessor(:str) # for debug
=begin
=end
  
    def initialize(command, trailing=nil, prefix=nil, *params)
=begin
initialize Message
  command:String
  trailing=nil:String
  prefix=nil:String
  *params:String
=end
      @prefix = prefix
      @command = command
      @params = params
      @trailing = trailing
      @str = to_s
    end

    def to_s 
=begin
String representation suitable for sending
=end
      buf = ''
      buf << ":" << @prefix << ' ' unless @prefix.nil?
      buf << @command
      buf << ' ' << @params.join(' ') unless @params.empty?
      buf << " :" << @trailing unless @trailing.nil?
      buf
    end

    alias_method(:to_extern, :to_s)
=begin
alias of to_s
=end
  end

  class << Message
    def parse(str)
=begin
parse IRC message and create a new Message object.
=end
      strbuf = str.dup
      strbuf.sub!(/^:(\S+)\s+/, '')
      prefix = $1 if $1
      strbuf.sub!(/^(\S+)/, '')
      command = $1 if $1
      params = []
      #while strbuf.sub!(/^\s+([^\s:]+)/, '')
      while strbuf.sub!(/^\s+([^\s:][^\s]*)/, '')
	params << $1
      end
      strbuf.sub!(/^\s+:([^\r\n]+)(\r\n|\r|\n)?$/, '')
      trailing = $1 if $1
      msg = new(command, trailing, prefix, *params)
      msg.str = str # for debug
      msg
    end
  end

  class User
=begin
represent IRC user
=end
    attr_reader(:nick)
    attr_reader(:user)
    attr_reader(:host)
    def initialize(nick, user=nil, host=nil)
      @nick, @user, @host = nick, user, host
    end
    def to_s
      "#{@nick}(#{user}) at #{@host}"
    end
    def ==(other)
      case other
      when User
	@nick == other.nick && @user == other.user && @host == other.host
      else
	false
      end
    end
  end
  class << User
    def parse(str)
      str =~ /([^\s!@]+)(?:!([^\s@]+))?(?:@(\S+))?/
      User::new($1, $2, $3)
    end
  end

  class LogMessage
=begin
class which represents log message
=end
    attr_reader(:timestamp)
=begin
:Time the time when this object was sent
=end
    attr_reader(:sender)
=begin
:Object the object which sent object
=end
    attr_reader(:ident)
=begin
:String identifier for message type
=end
    attr_reader(:message)
=begin
:String log message string
=end
    def initialize(sender, ident, message)
=begin
initialization
  sender:Object the object which sent object
  ident:String identifier for message type
  message:String string as message
  message:Message message object
=end
      @timestamp = Time.now
      @sender, @ident, @message = sender, ident, message
    end
    def to_s 
=begin
string in standard output form
=end
      buf = @timestamp.to_s
      case @sender
      when Connection, Client
	buf << " <#{@ident}> #{@message}"
      when Agent
	buf << " [#{@sender.nick}] #{@message}"
      end
      buf
    end
  end

  class Connection
=begin
represent IRC connection
=end

    include Constants

    def Message(command, trailing=nil, prefix=nil, *params)
=begin
alias of IRC::Message::new
=end
      Message.new(command, trailing, prefix, *params)
    end

    def initialize(log_queue=nil)
=begin
initialize Connection
  log_queue:Queue -- queue object into which log message are put.
=end
      @log_queue = log_queue
    end

    private
    def putlog(ident, str)
=begin
put a log message.
=end
      #@log_queue.push(Time.now.to_s+": "+str.to_s) unless @log_queue.nil?
      @log_queue.push(LogMessage.new(self, ident, str)) unless @log_queue.nil?
    end
    public

    def connect(server, port=DEFAULT_PORT)
=begin
Connect to server which has hostname given by argument server.
If sub-class of BasicSocket is given, it will be used.
  server:String -- server name.
  server:BasicSocket -- socket already connected to server.
  port=DEFAULT_PORT:Fixnum -- TCP port number. 6667 will be used when omitted.
=end
      if server.is_a?(BasicSocket)
	@socket = server
      else
	@server = server
	@port = port
	@socket = TCPsocket.open(@server, @port)
      end
      @socket.set_codesys("JIS")
    end

    def disconnect
=begin
=end
      @socket.flush
      @socket.shutdown(2)
      @socket.close
    end

    def send(*args)
=begin
send IRC message.
send(message)
  message:Message a IRC message to be send
send(command, trailing, prefix, *params)
  Send a message which consists of given arguments.
  Refer to Message#initialize about the meaning of the arguments.
=end
      case args.length
      when 1
	case args[0]
	when Message
	  message = args[0]
	  @socket.lprint(message, CRLF)
	  putlog("send", message)
	when String
	  command = args[0]
	  message = Message(command)
	  @socket.lprint(message, CRLF)
	  putlog("send1", message)
	else
	  putlog("send", "Type error(#{message.inspect}).")
	end
      when 0, 2
	putlog("send", "Argument number error.")
      else
	message = Message(*args)
	@socket.lprint(message, CRLF)
	putlog("send1", message)
      end
    end
#     def send(message)
#       @socket.lprint(message, CRLF)
#       putlog("send", message.to_s)
#     end

    def recv 
=begin
Receive IRC message and return as Message object.
This method will block.
=end
      str = @socket.lgets
      unless str.nil?
	message = Message.parse(str)
      else
	message = nil
      end
      putlog("recv", message)
      message
    end

    def sendPASS(password)
      send(Message(CMD_PASS, nil, nil, password))
    end
    def sendNICK(nick)
      send(Message(CMD_NICK, nil, nil, nick))
    end
    def sendUSER(nick, username, hostname, servername, realname)
      send(Message(CMD_USER, realname, nick,
		   username, hostname, servername))
    end
    def sendQUIT(nick, quit_message)
      send(Message(CMD_QUIT, quit_message, nick))
    end
=begin
send IRC messages about IRC connection.
=end
    
    def sendPING(nick, servers)
      send(Message(CMD_PING, nil, nick, servers))
    end
    def sendPONG(nick, daemons, phrase=nil)
      send(Message(CMD_PONG, phrase, nick, daemons))
    end
=begin
send IRC messages PING/PONG.
=end

#     # send IRC messages about channel
#     def sendJOIN(nick, channels, keys)
#       if channels.is_a?(Array)
# 	channels = channels.join(",")
#       end
#       if keys.is_a?(Array)
# 	keys = keys.join(",")
#       end
#       send(Message(CMD_JOIN, nil, nick, channels, keys))
#     end
#     def sendPART(nick, channels)
#       if channels.is_a?(Array)
# 	channels = channels.join(",")
#       end
#       send(Message(CMD_PART, nil, nick, channels))
#     end
    
#     # send IRC messages about sending messages
#     def sendPRIVMSG(nick, message, *channels)
#       send(Message(CMD_PRIVMSG, message, nick, *channels))
#     end
    
  end
end

