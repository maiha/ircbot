=begin header
Internet Relay Chat Protocol Library -- Constants

  $Author: igarashi $
  $Date: 2000/06/12 15:52:00 $

  Copyright (C) 1998-2000 Hiroshi IGARASHI
=end

module IRC
  module Constants
=begin
module in which IRC constants are defined
=end

    ERR_NOSUCHNICK = "401"
    ERR_NOSUCHSERVE = "402"
    ERR_NOSUCHCHANNEL = "403"
    ERR_CANNOTSENDTOCHAN = "404"
    ERR_TOOMANYCHANNELS = "405"
    ERR_WASNOSUCHNICK = "406"
    ERR_TOOMANYTARGETS = "407"
    ERR_NOORIGIN = "409"
    ERR_NORECIPIENT = "411"
    ERR_NOTEXTTOSEND = "412"
    ERR_NOTOPLEVE = "413"
    ERR_WILDTOPLEVEL = "414"
    ERR_UNKNOWNCOMMAND = "421"
    ERR_NOMOTD = "422"
    ERR_NOADMININFO = "423"
    ERR_FILEERROR = "424"
    ERR_NONICKNAMEGIVEN = "431"
    ERR_ERRONEUSNICKNAME = "432"
    ERR_NICKNAMEINUSE = "433"
    ERR_NICKCOLLISION = "436"
    ERR_USERNOTINCHANNEL = "441"
    ERR_NOTONCHANNE = "442"
    ERR_USERONCHANNEL = "443"
    ERR_NOLOGIN = "444"
    ERR_SUMMONDISABLED = "445"
    ERR_USERSDISABLED = "446"
    ERR_NOTREGISTERED = "451"
    ERR_NEEDMOREPARAM = "461"
    ERR_ALREADYREGISTRE = "462"
    ERR_NOPERMFORHOST = "463"
    ERR_PASSWDMISMATCH = "464"
    ERR_YOUREBANNEDCREEP = "465"
    ERR_KEYSET = "467"
    ERR_CHANNELISFULL = "471"
    ERR_UNKNOWNMODE = "472"
    ERR_INVITEONLYCHAN = "473"
    ERR_BANNEDFROMCHAN = "474"
    ERR_BADCHANNELKEY = "475"
    ERR_NOPRIVILEGES = "481"
    ERR_CHANOPRIVSNEEDED = "482"
    ERR_CANTKILLSERVER = "483"
    ERR_NOOPERHOST = "491"
    ERR_UMODEUNKNOWNFLAG = "501"
    ERR_USERSDONTMATCH = "502"
=begin
Error Replies
=end

    RPL_NONE = "300"
    RPL_USERHOST = "302"
    RPL_ISON = "303"
    RPL_AWAY = "301"
    RPL_UNAWAY = "305"
    RPL_NOWAWAY = "306"
    RPL_WHOISUSER = "311"
    RPL_WHOISSERVER = "312"
    RPL_WHOISOPERATOR = "313"
    RPL_WHOISIDLE = "317"
    RPL_ENDOFWHOIS = "318"
    RPL_WHOISCHANNELS = "319"
    RPL_WHOWASUSER = "314"
    RPL_ENDOFWHOWAS = "369"
    RPL_LISTSTART = "321"
    RPL_LIST = "322"
    RPL_LISTEND = "323"
    RPL_CHANNELMODEIS = "324"
    RPL_NOTOPIC = "331"
    RPL_TOPIC = "332"
    RPL_INVITING = "341"
    RPL_SUMMONING = "342"
    RPL_VERSION = "351"
    RPL_WHOREPLY = "352"
    RPL_ENDOFWHO = "315"
    RPL_NAMREPLY = "353"
    RPL_ENDOFNAME = "366"
    RPL_LINKS = "364"
    RPL_ENDOFLINKS = "365"
    RPL_BANLIST = "367"
    RPL_ENDOFBANLIST = "368"
    RPL_INFO = "371"
    RPL_ENDOFINFO = "374"
    RPL_MOTDSTART = "375"
    RPL_MOTD = "372"
    RPL_ENDOFMOTD = "376"
    RPL_YOUREOPER = "381"
    RPL_REHASHING = "382"
    RPL_TIME = "391"
    RPL_USERSSTART = "392"
    RPL_USERS = "393"
    RPL_ENDOFUSERS = "394"
    RPL_NOUSERS = "395"

    RPL_TRACELINK = "200"
    RPL_TRACECONNECTING = "201"
    RPL_TRACEHANDSHAKE = "202"
    RPL_TRACEUNKNOWN = "203"
    RPL_TRACEOPERATOR = "204"
    RPL_TRACEUSER = "205"
    RPL_TRACESERVER = "206"
    RPL_TRACENEWTYPE = "208"
    RPL_TRACELOG = "261"
    RPL_STATSLINKINF = "211"
    RPL_STATSCOMMANDS = "212"
    RPL_STATSCLINE = "213"
    RPL_STATSNLINE = "214"
    RPL_STATSILINE = "215"
    RPL_STATSKLINE = "216"
    RPL_STATSYLINE = "218"
    RPL_ENDOFSTATS = "219"
    RPL_STATSLLINE = "241"
    RPL_STATSUPTIME = "242"
    RPL_STATSOLINE = "243"
    RPL_STATSHLINE = "244"
    RPL_UMODEIS = "221"
    RPL_LUSERCLIENT = "251"
    RPL_LUSEROP = "252"
    RPL_LUSERUNKNOWN = "253"
    RPL_LUSERCHANNELS = "254"
    RPL_LUSERME = "255"
    RPL_ADMINME = "256"
    RPL_ADMINLOC1 = "257"
    RPL_ADMINLOC2 = "258"
    RPL_ADMINEMAIL = "259"
=begin
Message Replies
=end

    # generating mapping "XXX" -> <error name>
    table = {}
    constants.each { |name|
      table[const_get(name)] = name
    }
    NAME_TABLE = table
=begin
Mapping "XXX" -> <error name>
=end

    #
    # Message Commands
    #
    CMD_PASS = "PASS"
    CMD_NICK = "NICK"
    CMD_USER = "USER"
    CMD_SERVER = "SERVER"
    CMD_OPER = "OPER"
    CMD_QUIT = "QUIT"
    CMD_SQUIT = "SQUIT"
=begin
Connection messages
=end

    CMD_JOIN = "JOIN"
    CMD_PART = "PART"
    CMD_MODE = "MODE"
    CMD_TOPIC = "TOPIC"
    CMD_NAMES = "NAMES"
    CMD_LIST = "LIST"
    CMD_INVITE = "INVITE"
    CMD_KICK = "KICK"
=begin
Channel control messages
=end

    CMD_VERSION = "VERSION"
    CMD_STATS = "STATS"
    CMD_LINK = "LINK"
    CMD_TIME = "TIME"
    CMD_CONNECT = "CONNECT"
    CMD_TRACE = "TRACE"
    CMD_ADMIN = "ADMIN"
    CMD_INFO = "INFO"
=begin
Query and messages for server
=end

    CMD_PRIVMSG = "PRIVMSG"
    CMD_NOTICE = "NOTICE"
=begin
Message sending
=end

    CMD_WHO = "WHO"
    CMD_WHOIS = "WHOIS"
    CMD_WHOWAS = "WHOWAS"
=begin
Request for user information
=end

    CMD_KILL = "KILL"
    CMD_PING = "PING"
    CMD_PONG = "PONG"
    CMD_ERROR = "ERROR"
=begin
Others
=end

    CMD_AWAY = "AWAY"
    CMD_REHASH = "REHASH"
    CMD_RESTART = "RESTART"
    CMD_SUMMON = "SUMMON"
    CMD_USERS = "USERS"
    CMD_WALLOPS = "WALLOPS"
    CMD_USERHOST = "USERHOST"
    CMD_ISON = "ISON"
=begin
Optional
=end

    #
    # Other constants
    #

    CRLF = "\r\n"
=begin
Message separator
=end

    DEFAULT_PORT = 6667
=begin
Default TCP Port
=end
    
  end
end

#p IRC::Constants::NAME_TABLE

