# Extension to ruby-irc-lib

module IRC
  class AbnormalTerminated < Exception; end

  class Connection
    def sendNAMES (channel = nil)
# p [:sendNAMES, Message(CMD_NAMES, nil, nil, channel)]
      send(Message(CMD_NAMES, nil, nil, channel))
    end
  end

  class Message
    def create_hash! (client)
      unless @hash
	@hash = {}
	@hash[:client] = client
	@hash[:type]   = self.command
	@hash[:prefix] = self.prefix
	@hash[:from]   = User::parse(self.prefix).nick
        @hash[:str]    = self .trailing
        @hash[:string] = @hash[:str]
	@hash[:to]     = to = self .params[0]
	@hash[:timestamp] = Time .now

	unless to
	  case self .command
	  when CMD_JOIN, CMD_QUIT
	    @hash[:to] = to = @hash[:str]
	  end
	end

        if to != nil and to == client .nick
	  @hash[:to] = @hash[:from]
        end
	if client .is_a? Client
	  @client = client
	end
      end
    end

    def [] (key)		# key must be a symbol
      @hash[key]
    end

    def []= (key, val)
      @hash[key] = val
    end

    def reply (string, to = nil)
      self[:reply] = string
      if @client and string
	@client .speak(self, to)
      end
    end

    def previous
      @client && @client .previous_message(self)
    end
  end
end
