# -*- coding: euc-jp -*-

require 'ircbot/agent_manager'

module Ircbot
  class ConfigClient < IRC::Client
    attr :config
    attr :messages
    attr :agents

    PARAM_STRING = %w( nick server username realname password port log syslog help pidfile )
    PARAM_ARRAY  = %w( agents channels )
    PARAM_KEYS   = PARAM_STRING + PARAM_ARRAY

    class << self
      ######################################################################
      ### config ファイルから設定値を読み込み、Client オブジェクトを作成
      ######################################################################
      def read_config(input, debug = nil)
	case input
	when IO			# already IO (NOP)
	when String		# maybe file
	  begin
	    input = File.open(input)
	  rescue Exception
	    $stderr.puts("cannot read config file. (#{input})")
	    exit
	  end
	else
	  $stderr.puts("missing config file.")
	  exit
	end

	params		= {}
	param_regexp	= self::PARAM_KEYS.join('|')
	while (line = input.gets)
	  case line
	  when /^#/		# ignore
	  when /^(#{param_regexp})\s*=\s*/io
	    key, val = $1.downcase, $'.chomp
	    symbol = key.intern
	    case key
	    when *self::PARAM_STRING
	      params[symbol] = val
	    when *self::PARAM_ARRAY
	      params[symbol] = val.split(/[,\s]+/)
	    else		# IGNORE...
	      $stderr.puts "ignore: #{key} = #{params[symbol].inspect}(#{params[symbol].class})"
	    end
	    if debug
	      $stderr.puts "debug: #{key} = #{params[symbol].inspect}(#{params[symbol].class})"
	    end
	  end
	end
	self.new(params)
      end
    end

    def initialize (hash = {})
      @config	= hash

      # 必須項目
      @nick	= hash[:nick]			|| missing_error(:nick)
      @server	= hash[:server]			|| missing_error(:server)
      @username = hash[:username] || @nick	|| missing_error(:username)
      @realname = hash[:realname] || @nick	|| missing_error(:realname)
      @channels	= hash[:channels]

      @port	= hash[:port]		|| 6667
      @password = hash[:password]	|| 'xxx'
      @log	= hash[:log]
      @syslog	= hash[:syslog]
      @help	= hash[:help]		|| 'ヘルプがありません。(config の help 行を見ます)'
      @agents	= OrderedHash.new	# String→Agent

      @agents_opt = {}          # エージェントの起動に利用するオプション

      @mynames		= [@nick, @realname].compact.sort.uniq
      @cachesize	= (hash[:cachesize].to_i < 1) ? 100 : hash[:cachesize].to_i
      @last_message_id	= 0
      @messages		= []

      @last_ping_time	= nil   # 最後に CMD_PING を受け取った時間
    end

    def missing_error (arg)
      syslog("#{arg}が指定されていません", :fatal)
    end

    def syslog (message, level = :normal)
      line = Time.now.strftime("%Y-%m-%d %H:%M:%S #{message}")
      case level
      when :normal
	if @syslog
	  File.open!(@syslog, "a+") {|file| file.puts line; file.flush}
	end
      when :error
	syslog(message, :normal)
	$stderr.puts line
      when :fatal
	syslog(message, :error)
	exit 1
      else
	syslog("syslog: wrong level(#{level}): mes=[#{message}]", :error)
      end
    end

    def write_pid_file
      # write pid information to a file
      filename = config[:pidfile]
      pid = Process::pid
      if filename
	if exist_process?
	  raise "another process is running. (pid=#{pid})"
	end
	File::write!(pid.to_s, filename, 'w+')
	File::chmod(0664, filename)
      end
    end

    def exist_process?
      filename = config[:pidfile]	or return nil
      File::exists?(filename)		or return nil
      pid = File::open(filename).read	or return nil

      begin
	Process::getpgid(pid.to_i)
	return pid.chomp
      rescue Errno::ESRCH
	return nil
      end
    end

    def do_log (message)
      begin
	case @log
	when NilClass
	  return nil
	when /\/$/
	  format = "#{@log}/%Y%m/%d.log"
	when String
	  format = @log
	else
	  syslog("do_log: unknown type #{@log.class}", :error)
	  @log = nil
	  return nil
	end

	now  = Time.now
	path = now.strftime(format)
	from = message[:from]
	to   = message[:to]
	str  = message[:str]

	File.open!(path, "a+") {|file|
	  file.puts now.strftime("%H:%M <#{to}:#{from}> #{str}")
	}
	return nil
      rescue
	syslog("do_log: #{$!}", :error)
	@log = nil
      end
    end


    ######################################################################
    ### IRC のコネクション関係
    ######################################################################

    def start
      write_pid_file
      syslog("#{self.class}: system starts.")

      create_message_thread

      # 再接続の為に、initialize 内でなくここで呼び出す。

      connect
      join

      # エージェントの登録
      @config[:agents].each do |name|
        registerAgent(name)
      end
      each_agent {|agent| agent.start}

      startThreads
      @message_thread.join
      @log_thread.raise(Stop.new)
      @log_thread.join
    end

    def ping_timeout
      stop
      exit
    end

    def startThreads
      super
      @ping_thread = Thread.start {
        eprintln("ping_thread started.") if $DEBUG
        #_putlog("debug", "ping_thread started.")
        sec = 3600 # この秒数 PING がないと ping_timeoutを呼ぶ
        while true
          sleep 60
          case @last_ping_time
          when Time
            if Time.now > @last_ping_time + sec
              ping_timeout
            end
          end
        end
        eprintln("ping_thread stopped.") if $DEBUG
        #_putlog("debug", "ping_thread stopped.")
      }
      eprintln("ping_thread created.") if $DEBUG
    end

    # derived from original ruby-irc::Client#stop
    def stop
      # Agentの停止
      each_agent do |agent|
	agent.stop
      end

      disconnect
      @message_thread.raise(Stop.new)
      destroy_message_thread
    end

    # derived from original ruby-irc::Client's one.
    def connect 
      @log_queue	= Queue.new
      @connection	= Connection::new(@log_queue)

      @connection.connect(@server, @port.to_s)
      @connection.sendPASS(@password)
      @connection.sendNICK(@nick)
      @connection.sendUSER(nil, @username, "hostname", "servername", @realname)
    end

    # derived from original ruby-irc::Client's one.
    def disconnect 
      @connection.sendQUIT(@nick, nil)
      @connection.disconnect
    end

    def join
      channels	= @channels.join(',')
      @connection.send(CMD_JOIN, nil, @nick, channels, '')
    end

    def names (channel = nil)
      @connection.sendNAMES(channel)
    end

    ######################################################################
    ### Message Handling
    ######################################################################

    def handlePING(msg)
#      p [:handlePING, Time.now]
      super
      @last_ping_time = Time.now
    end

    def add_message (msg)
      index = (@last_message_id += 1) % @cachesize
      @messages[index] = msg

      return index
    end

    def previous_message (msg)
      index = (@cachesize + msg[:id].to_i - 1) % @cachesize
      @messages[index]
    end

    def last_messages (size)
      mes = @messages[@last_message_id % @cachesize] or return []
      array = []
      i = 0
      j = 0

      while (size > 0)
        j += 1
        break if i > @cachesize # maybe looping. give up
        break if j > 100
        break unless mes

        i += 1
#        p [mes[:from],mes[:to],mes[:str], size, i, mes[:from] == mes[:to]]
        unless mes[:from] == mes[:to]
          array << mes
          size -= 1
        end
        mes = mes.previous
      end
      return array
    end

    # created by yu-yan@4th.to
    def create_message_thread
      @message_last   = nil
      @message_timer  = Time.now
      @message_queue  = Queue.new
      @message_thread = Thread.new(@message_timer, @message_queue) { |message_timer, message_queue|
	loop {
	  now           = Time.now
	  message_timer = [message_timer, now].max + 2

	  if (message_timer - now) > 15
	    sleep(3)
	  else
	    sleep(0.1)
	  end

#	  STDERR.print("timer:#{message_timer.strftime('%H:%M:%S')} - now:#{now.strftime('%H:%M:%S')} = #{message_timer - now}\n")

	  message, to = message_queue.pop
	  privmsg(message, to)
#	  STDERR.print("MSG:", message, "\n")
	}
      }
    end

    def destroy_message_thread
      if @message_thread.is_a? Thread
	@message_thread.kill
      end
    end

    # derived from original ruby-irc::Client's one.
    def handleMessageLoop 
      loop do
        msg = @connection.recv
        if msg.nil?
          syslog("handleMessageLoop: Abnormal terminated.", :error)
	  abnormal_terminated
        end
        handleMessageInternal(msg)
        distributeMessage(msg)
      end
    end

    def abnormal_terminated
      raise IRC::AbnormalTerminated
    end
  end
end
