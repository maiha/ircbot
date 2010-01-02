# -*- coding: euc-jp -*-

module Ircbot
  ######################################################################
  ### agent を管理するクラス
  ### (直接 agent を利用しないのは、agent の管理も併せて行うから)
  ######################################################################
  class AgentManager
    attr :cpi, true
    attr :name
    attr :created
    attr :alive

    def initialize (name, obj, client, arg = nil)
      @name	= name
      @cpi	= obj
      @created	= Time.now
      @alive	= nil
      @client	= client
      @arg      = arg

      method = :do_construct
      if @cpi.respond_to?(method)
	@cpi.send(method, client)
      end
    end

    def notifyMessage (msg)
      # NOP
    end

    def start (arg = nil)
      @arg = arg if arg

      method = :do_start
      if @cpi.respond_to?(method)
	@cpi.send(method, @arg)
      end

      @alive = true
    end

    def stop
      method = :do_destruct
      if @cpi.respond_to?(method)
	@cpi.send(method, nil)
      end
      @alive = nil
    end

    def alive?
      @alive
    end

    def send (method, *args)
      if alive?
	return @cpi.send(method, *args)
      else
	return nil
      end
    end

    # 指定されたメソッド群を順次実行する
    # 1つ実行したら終了。どのメソッドも具備してない場合は nil を返す。
    def apply_methods (msg, methods)
      methods = [methods] unless methods.is_a? Array
      methods.each do |method|
	next unless @cpi.respond_to?(method)
	begin
	  if msg
	    if (result = send(method, msg))
	      return result
	    end
	  else
	    if (result = send(method))
	      return result
	    end
	  end
	rescue Exception => err
	  error = "error: #{err} in #{self.name}"
	  @client.syslog(error, :error)
	  @client.syslog($@.join("\n"), :error)
	  return error
	end
      end
      return nil
    end
  end
end
