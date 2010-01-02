# -*- coding: euc-jp -*-

require 'ircbot/config_client'

module Ircbot
  class ReplyClient < ConfigClient
    DIGEST_MAX_SIZE = 400
    REGEXP_REDIRECT = ">|＞"

    def myname_regexp_string
      names = @mynames.join('|')
      "(#{ names })"
    end

    def speak0 (to, obj, save = nil)
      Thread.critical = true
      message =
        case obj
        when String     ; obj
        when Array
          array = obj.collect {|item| item.inspect}.join(', ')
          "(#{obj.size})[#{array}]"
        when Regexp     ; "/#{obj.source}/"
        else            ; obj.inspect
        end

      message.split(/\n+/).each do |line|
	buffer = line.digest(DIGEST_MAX_SIZE)
	unless buffer.empty?
	  # メッセージを送信する
	  @message_queue.push([buffer, to])

          # メッセージオブジェクトを作成して、@messages に残す
          if save
            # :AnnaChan!~anna@219-106-253-19.cust.bit-drive.ne.jp PRIVMSG #bot :test\r\n"
            str = ":#{@nick}!~bot@localhost PRIVMSG #{@channel} :#{buffer}\r\n"
            msg = Message::parse(str)
            msg.create_hash!(self)
            msg[:id] = add_message(msg)
          end
	end
      end
      Thread.critical = false
    end

    def speak (msg, to = nil, log = nil)
      speak0(to || msg[:to], msg[:reply], log)
    end

    def newAgent (name)
      script = Ircbot.path_for(:cpi, "#{name}.cpi").read{}
      eval(script, TOPLEVEL_BINDING)

    rescue SecurityError => e
      err = "#{e.class}: #{e}"
      syslog(err, :error)
      return err
    end

    # xxxAgent: Agent を xxx する
    # 引数: String (Agent の識別子)
    # 戻値: String (メッセージ)

    # エージェントの新規登録
    def registerAgent (name0)
      						# ex) name0="daiben(12345)"
      name, arg = name0.split(/\s|\(/, 2)	# ex) name="daiben"
      arg = arg.to_s.delete(")").strip	# ex) arg="12345"

      err    = nil
      this   = "registerAgent"
      agent  = @agents[name]
      @agents_opt[name] = arg

#      p [:debug, :registerAgent, name0, name, arg]

      agent = newAgent(name)
      case agent
      when NilClass
	err = "Agent plugin script return nil (will not be registerd)."
      when String
	err = agent
      else
	@agents[name] = AgentManager.new(name, agent, self, arg)
      end

      status = "#{this}(#{name})... #{err || 'OK.'}"
      syslog(status, err ? :error : :normal)
      return status
    end

    def startAgent (name0)
      						# ex) name0="daiben(12345)"
      name, arg = name0.split(/\s|\(/, 2)	# ex) name="daiben"
      arg = arg.to_s.delete(")").strip	# ex) arg="12345"

      err   = nil
      this  = "startAgent"
      agent = @agents[name]
      arg   = @agents_opt[name] if arg.empty?

      case agent
      when NilClass
	err = "no such agent."
      when AgentManager
	agent.start(arg)
      else
	err = "unknown agent type(#{agent.class})."
      end

      status = "#{this}(#{name})... #{err || 'OK.'}"
      syslog(status, err ? :error : :normal)
      return status
    end

    def removeAgent (name)
      err    = nil
      this   = "removeAgent"
      agent  = @agents[name]

      case agent
      when NilClass
	err = "no such agent."
      when AgentManager
	agent.stop
	@agents.delete(name)
      else
	err = "unknown agent type(#{agent.class})."
      end

      status = "#{this}(#{name})... #{err || 'OK.'}"
      syslog(status, err ? :error : :normal)
      return status
    end

    # Agent の再起動
    def restartAgent (name)
      err    = nil
      this   = "restartAgent"
      agent  = @agents[name]

      case agent
      when NilClass
	err = "no such agent."
      when AgentManager
	agent.stop
	obj = newAgent(name)
	case obj
	when NilClass
	  err = "Agent plugin script return nil (will not be registerd)."
	when String
	  err = agent
	else
          arg = @agents_opt[name]
	  agent = AgentManager.new(name, obj, self, arg)
	  @agents[name] = agent
	  agent.start
	end
      else
	err = "unknown agent type(#{agent.class})."
      end

      status = "#{this}(#{name})... #{err || 'OK.'}"
      syslog(status, err ? :error : :normal)
      return status
    end

    def stopAgent (name)
      err   = nil
      this  = "stopAgent"
      agent = @agents[name]

      case agent
      when NilClass
	err = "no such agent."
      when AgentManager
	agent.stop
      else
	err = "unknown agent type(#{agent.class})."
      end

      status = "#{this}(#{name})... #{err || 'OK.'}"
      syslog(status, err ? :error : :normal)
      return status
    end

    def do_help (msg)
      target = msg[:arg].to_s.strip
      if target.empty?
	# ボットのヘルプ＋cpi一覧を返す
	alives = 0
	names  = @agents.collect {|name, agent|
	  if agent.alive?
	    alives += 1
	    name = "*#{name}"
	  end
	  name
	}.join(', ')
	msg[:reply] = "#{@help}\ncpi(#{alives}/#{@agents.size}): #{names}"
	speak(msg)

      else
	# 個別に cpi のヘルプを返す。
	target = target.delete('()[] ')
	@agents.each_pair do |name, agent|
	  next unless target == name
	  next unless (result = agent.apply_methods(msg, :do_help))
 	  msg[:reply] = result
 	  speak(msg)
 	end
      end
    end

    def parse_command (msg)
      case msg[:type].to_s
      when CMD_PRIVMSG
	case msg[:str].to_s
	when /^\s*#{myname_regexp_string}\s*(\.\s*[^\s\(]+)/o
	  msg[:called]  = $1
	  msg[:command] = $2
	  msg[:arg]     = $'.to_s.strip
	  msg[:command].gsub!(/^\./, '') if msg[:command]
	when /(#{REGEXP_REDIRECT})\s*#{myname_regexp_string}\s*(\.\s*[^\s\(]+)?\s*$/o
	  msg[:arg]     = $`.to_s.strip
	  msg[:called]  = $2
	  msg[:command] = $3
	  msg[:command].gsub!(/^\./, '') if msg[:command]
	end	  
      end
      return msg
    end

    def distributeMessage (msg)
      # prepare accessors for dummy agents
      msg.create_hash!(self)
      msg[:id] = add_message(msg)
      msg = parse_command(msg)

# p [msg[:type], msg[:from], msg[:from].to_s.empty?, msg[:str]]

      # 身元不明なメッセージ(PING等)は無視
      if msg[:from].to_s.empty?
	return nil
      end

      begin
	# reserved commands
        name = msg[:arg].to_s.sub(/\A\s*\(?\s*/, '')
        name = name.sub(/\s*\)?\s*\Z/, '') unless name.include?('(')

	case msg[:command].to_s
	when /^restart$/
	  names = name.split(/\s*,?\s+/)
	  names = @agents.keys if names.empty?
	  names.each do |name|
	    msg.reply(restartAgent(name))
	  end
	  return nil
	when /^register$/	; msg.reply(registerAgent(name)); return msg.reply(startAgent(name))
	when /^remove$/		; return msg.reply(removeAgent(name))
	when /^start$/		; return msg.reply(startAgent(name))
	when /^stop$/		; return msg.reply(stopAgent(name))
	when /^help$/		; return do_help(msg)
	end

	case msg[:type].to_s
	when CMD_JOIN	; each_agent {|agent| agent.apply_methods(msg, :do_join)}
	when CMD_PART	; each_agent {|agent| agent.apply_methods(msg, :do_part)}
	when CMD_PING	; each_agent {|agent| agent.apply_methods(msg, :do_ping)}
	when RPL_NAMREPLY
#	  p [:debug, :get_CMD_NAMES]
          each_agent {|agent| agent.apply_methods(msg, :do_names)}
	when CMD_PRIVMSG

	  # ログの書き出し
	  if @log
	    do_log(msg)
	  end

	  # do_log の前に呼び出す。(過去ログを利用する場合のため)
	  message = nil
	  catch(:reply) {
	    if msg[:called]
	      each_agent do |agent|
		next unless (message = agent.apply_methods(msg, :do_command))
		throw :reply
	      end
	    else
	      each_agent do |agent|
		next unless (message = agent.apply_methods(msg, :do_reply))
		throw :reply
	      end
	    end
	  }

	  # Agent#do_log の呼び出し
	  each_agent do |agent|
	    msg.reply(agent.apply_methods(msg, :do_log))
	  end
          
          # 自分の発言も記録
          if message != nil then
            dummy = {}
            dummy[:str]  = message
            dummy[:from] = @nick
            dummy[:to]   = @channels
            each_agent { |agent|
              msg.reply(agent.apply_methods(dummy, :do_log))
            }
          end

	  return msg.reply(message)
	end
      rescue Exception
	syslog("distributeMessage: #{$!}(#{$@[0]})", :error)
      end
    end
  end
end


if $0 == __FILE__
  config = ARGV.shift or
    raise "Specify your config file\nusage: #{$0} config/xxx.dat"
  irc = IRC::ReplyClient.read_config(config)
  irc.start
end

