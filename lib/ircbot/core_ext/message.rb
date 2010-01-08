######################################################################
### core_ext 

class Net::IRC::Message
  def channel
    params[0]
  end

  def message
    params[1]
  end

  def reply(client, text)
    to = (client.config.nick == params[0]) ? prefix.nick : params[0]
    client.privmsg to, text.to_s unless text.to_s.empty?
  end
end

