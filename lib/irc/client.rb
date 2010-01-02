=begin header
Internet Relay Chat Client Library

  $Author: knu $
  $Date: 2001/01/31 10:55:28 $

  Copyright (C) 1998-2000 Hiroshi IGARASHI
=end

require 'irc/irc'
require 'irc/agent'

if $DEBUG
  class << Thread
    alias _start start
    def start(&iter)
    eprintln("Thread created(#{caller}).")
      _start(&iter)
    end
  end
end

module IRC

  class NewAgentException < Exception
=begin
����������Ȥ������Ǥ��ʤ��ä����Ȥ򼨤��㳰
=end
  end

  class Stop < Exception
  end

  class Client
=begin
IRC���饤����ȤȤ��Ƥε�ǽ�����Ȥߤ�������륯�饹
=end
  
    include Constants

    attr_reader(:nick)
=begin
nick:String  �˥å��͡���
=end
    attr_reader(:agents)
=begin
agents:Hash  �Ȥ߹��ޤ�Ƥ��륨���������
=end
    attr_reader(:join_channels)
=begin
join_channels:Array of String  join���Ƥ�������ͥ�
=end
    
    def initialize(server, nick, username, realname=username)
=begin
Client�ν������Ԥ�
  server:String    ������̾
  nick:String      �˥å��͡���
  username:String  �桼��̾(������̾)
  realname:String  ��̾
=end
      @server = server
      @nick = nick
      @username = username
      @realname = realname
      #@passive_agents = {} # String��PassiveAgent
      #@active_agents = {}  # String��ActiveAgent
      @agents = {}  # String��Agent
      @join_channels = []
    end

    def connect 
=begin
�����Фؤ���³��Ԥ�
=end
      @connection.connect(@server, 6667)
      @connection.sendPASS("xxx")
      @connection.sendNICK(@nick)
      @connection.sendUSER(nil, @username,
                           "hostname", "servername", @realname)
    end

    def disconnect 
=begin
�����ФȤ���³���ڤ�
=end
      @connection.sendQUIT(@nick, nil)
      @connection.disconnect
    end

    def putlog(sender, ident, str)
=begin
���򥭥塼�������
=end
      @log_queue.push(LogMessage.new(sender, ident, str)) unless @log_queue.nil?
    end

    private
    def _putlog(ident, str)
=begin
���򥭥塼�������
=end
      #leprintln(ident , " ", str)
      putlog(self, ident, str)
    end
    public

    def newAgent(name)
=begin
����������Ȥ��������롣
Ϳ����줿̾���Υ���������Ȥ�ץ饰���󥹥���ץȤ���
��������������֤���
=end
      # �����������̾���ץ饰���󥹥���ץ�̾
      script_name = "cpi/" + name + ".cpi"
      begin
        script = File.open(script_name).read
      rescue Exception
        _putlog("newAgent:#{name}",
                "Reading agent plugin script '#{script_name}' raises exception(#{$!}).")
        raise NewAgentException.new
      end
      begin
        agent = eval(script)
        p(agent) if $DEBUG
        if agent.nil?
          _putlog("newAgent:#{name}",
                  "Agent plugin script return nil (will not be registerd).")
        else
          agent.name = name
          agent.script_name = script_name
        end
      rescue Exception
        _putlog("newAgent:#{name}",
               "Agent plugin script raises exception(#{$!}).")
        raise NewAgentException.new
      end
      unless agent.is_a?(Agent)
        _putlog("newAgent:#{name}", "Agent type warning(#{agent.type}).")
      end
      _putlog("newAgent:#{name}", "Agent generated(#{name}).")
      agent
    end

    def registAgent(name, agent)
=begin
����������Ȥ���Ͽ
=end
      case agent
      when Agent
        if @agents[name].nil?
          @agents[name] = agent
        else
          p(@agents) if $DEBUG
          _putlog("registAgent", "duplicate registration of agent(#{name}).")
        end
      else
        _putlog("registAgent", "agent type error.")
      end
      _putlog("registAgent", "agent registered(#{name}).")
      agent
    end

    def findAgent(name)
      agent = @agents[name]
#      if agent.nil?
#       _putlog("findAgent, "No such agent registered(#{name}).")
#      end
      agent
    end

    def removeAgent(name)
=begin
����������Ȥκ��
=end
      unless @agents[name].nil?
        @agents[name] = nil
      else
        _putlog("removeAgent", "can't remove agent(#{name}).")
      end
    end

    def startAgent(name)
=begin
����������Ȥε�ư
�ʴ��˵�ư���Ƥ����鲿�⤷�ʤ���
=end
      _putlog("startAgent", "called(#{name}).")
      old_agent = findAgent(name)
      if old_agent.nil?
        # ��ư���Ƥ��ʤ�
        begin
          new_agent = newAgent(name)
          return nil if new_agent.nil?
        rescue NewAgentException
          _putlog("startAgent", "can't start agent(#{name}).")
          return nil
        end
        begin
          case new_agent
          when ActiveAgent
            Thread.start do
              new_agent.start(self)
            end
          when PassiveAgent
            new_agent.start(self)
          else
          end
          registAgent(name, new_agent)
        rescue Exception
          _putlog("startAgent:#{name}",
                  "Agent#start raises exception(#{$!}).")
        end
      else
        # ��ư���Ƥ���ΤǤ�����֤�
        old_agent
      end
    end

    def stopAgent(name)
=begin
����������Ȥ����
=end
      agent = findAgent(name)
      agent.stop unless agent.nil?
    end

    def restartAgent(name)
=begin
����������ȤκƵ�ư�򤹤롣
���ꤵ�줿̾���Υ���������Ȥ���ߡ���������塢
�ץ饰���󥹥���ץȤ��饨��������Ȥ������������Ͽ���롣
name:String ����������Ȥ�̾����
=end
      stopAgent(name)
      removeAgent(name)
      startAgent(name)
    end

    def evolveAgent(name)
=begin
����������Ȥοʲ�
��message_thread����ƤӽФ��ʤ��ȡ���å������������ꤽ���ʤ�
��ǽ���������
=end
    end

    def start(init_cpi="init")
=begin
���饤����ȤȤ��Ƥ�ư��򳫻Ϥ��롣
  init_cpi:String  ��ư������ץ�
=end
      @syslog_agent = startAgent("syslog")
      @log_queue = Queue.new
      _putlog("client", "started.")
      eprintln("client started.") if $DEBUG
      @connection = Connection::new(@log_queue)
      connect
      _putlog("client", "connected to server.")
      startAgent(init_cpi)

      startThreads

      #Thread.join(@message_thread) # obsoleted
      @message_thread.join
      # syslog�����
      @syslog_agent.stop
      # log_thread�����
      _putlog("client", "stopped.")
      @log_thread.raise(Stop.new)
      #Thread.join(@log_thread) # obsoleted
      @log_thread.join
      p(@log_queue) if $DEBUG
    end

    def stop
      #Thread.start do
        _stop
      #end
    end
    private
    def _stop
      # Agent�����
      @agents.each do |name, agent|
        case agent
        when @syslog_agent
          leprintln("@syslog_agent skipped.") if $DEBUG
        when ActiveAgent
          agent.stop
        when PassiveAgent
          agent.stop
        else
        end
      end
      # Connection������
      disconnect
      # message_thread�����
      @message_thread.raise(Stop.new)
      #raise(Stop.new)
    end
    public

    def startThreads 
=begin
����åɤ�ư����
=end
      @message_thread = Thread.start {
        eprintln("message_thread started.") if $DEBUG
        #_putlog("debug", "message_thread started.")
        begin
          handleMessageLoop
        rescue Stop
        end
        eprintln("message_thread stopped.") if $DEBUG
        #_putlog("debug", "message_thread stopped.")
      }
      eprintln("message_thread created.") if $DEBUG
      @log_thread = Thread.start {
        eprintln("log_thread started.") if $DEBUG
        #_putlog("debug", "log_thread started.")
        handleLogLoop
        eprintln("log_thread stopped.") if $DEBUG
        #_putlog("debug", "log_thread stopped.")
      }
      eprintln("log_thread created.") if $DEBUG
      eprintln("threads created.") if $DEBUG
      p([@message_thread, @log_thread]) if $DEBUG
    end
    
    def handleMessageLoop 
=begin
�����ФȤΤ����򤹤롣
=end
      loop do
        msg = @connection.recv
        if msg.nil?
          _putlog("handleMessageLoop", "Abnormal terminated.")
          break
        end
        #p msg
        handleMessageInternal(msg)
        distributeMessage(msg)
      end
    end

    def handleMessageInternal(msg)
=begin
��å�������������ϥ�ɥ�˿���ʬ���롣
=end
      #lprintln("IRCClient#handleMessage")
      # msg���Ф������
      case msg.command
      when CMD_PING
        handlePING(msg)
      else
        # numeric reply/error���Ф������
        #leprintln("numeric reply/error���Ф������")
        name = NAME_TABLE[msg.command]
        unless name.nil?
          #_putlog("(#{name})", "#{msg.to_s}")
        else
          #raise "Unknown message#{msg.inspect}."
          #leprintln("Unknown message #{msg.inspect}.")
          #_putlog("(unknown msg)", "#{msg.to_s}")
        end
      end
    end
  
    def handlePING(msg)
=begin
��å������ϥ�ɥ顣
���֥��饹�ǥ����С��饤�ɤ���뤳�Ȥ����Ԥ���Ƥ��롣
=end
      @connection.sendPONG(nil, nil, msg.trailing)
    end
    
    def distributeMessage(msg)
=begin
��å�����������
=end
      @agents.each do |name, agent|
        case agent
        when ActiveAgent
          unless agent.message_queue.nil?
            agent.message_queue.push(msg)
          end
        when PassiveAgent
          begin
            agent.notifyMessage(msg)
          rescue
            _putlog("distributeMessage",
                    "Agent(#{name}) raise exception: #{$!}.")
          end
        else
          _putlog("distributeMessage", "Agent type error.")
        end
      end
    end

    def handleLogLoop 
=begin
���ν���
=end
      begin
        loop do
          log = @log_queue.pop
          #lprintln(log)
          eprintln("*********************") unless log.is_a?(LogMessage)
          #p(log)
          distributeLog(log)
        end
      rescue Stop
        until @log_queue.empty?
          log = @log_queue.pop
          eprintln("*********************") unless log.is_a?(LogMessage)
          distributeLog(log)
        end
      end
    end

    def distributeLog(log)
=begin
��������
=end
      @agents.each do |name, agent|
        #p([name, agent])
        case agent
        when ActiveAgent
          unless agent.log_queue.nil?
            agent.log_queue.push(log)
          end
        when PassiveAgent
          agent.notifyLog(log)
        else
          leprintln("distributeLog: ", "Agent(#{name}) type error.") if $DEBUG
          #_putlog("distributeLog", "Agent type error.")
        end
      end
    end

    #
    # ��å����������᥽�å�
    #

    def join(channels, keys)
      if channels.is_a?(Array)
        channels = channels.join(",")
      end
      if keys.is_a?(Array)
        keys = keys.join(",")
      end
      @connection.send(CMD_JOIN, nil, @nick, channels, keys)
    end
    def part(channels)
      if channels.is_a?(Array)
        channels = channels.join(",")
      end
      @connection.send(CMD_PART, nil, @nick, channels)
    end
=begin
�����ͥ����˴ؤ���IRC��å�����
=end
    
    def privmsg(message, *channels)
      @connection.send(CMD_PRIVMSG, message, @nick, *channels)
    end

    def action(message, *channels)
      @connection.send(CMD_PRIVMSG, "\001ACTION #{message}\001", @nick, *channels)
    end
=begin
��å����������˴ؤ���IRC��å�����
=end
  end
end

