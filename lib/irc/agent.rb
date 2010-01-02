=begin header
Internet Relay Chat Agent Library

  $Author: knu $
  $Date: 2001/01/31 10:55:28 $

  Copyright (C) 1998-2000 Hiroshi IGARASHI
=end

#require 'irc'
#require 'ircclient'

module IRC
  class Agent
=begin
IRC���ư���agent�����Ȥߤ��󶡤��륯�饹��
���������᥽�åɤ�override�������Ѥ���
=end

    include Constants

    #attr_reader(:name)
    attr_accessor(:name)
=begin
�����������̾(������ץ�̾��1��1�б�):String
=end
    attr_reader(:nick)
=begin
�����������̾:String
=end
    attr_reader(:timestamp)
=begin
��������:Time
=end
    attr_accessor(:script_name)
=begin
������������ץȥե�����̾:String
=end

    def initialize(nick=__id__.to_s)
=begin
�����Τ߹Ԥ��ʼºݤν������start�ǹԤ���
=end
      @nick = nick
      @timestamp = Time.now
    end
    def start(client)
=begin
���������ư
  client:Client ����Agent���Ȥ߹��ޤ��Client���֥�������
=end
      @client = client
      putlog("start", "started.")
      main
    end
    def restart(old_agent)
=begin
�Ƶ�ư
  old_agent:Agent nil�ʤ�и��ߤξ��֤Τޤ�ư���
=end
    end
    def stop
=begin
���
=end
      putlog("stop", "stopped.")
      #leprintln("#{@nick} stoped.")
    end

    def putlog(ident, str)
      @client.putlog(self, ident, str)
    end
    def join(channels, keys)
      @client.join(channels, keys)
    end
    def part(channels)
      @client.part(channels)
    end
    def privmsg(message, *channels)
      @client.privmsg(message, *channels)
    end
    def action(message, *channels)
      @client.action(message, *channels)
    end
=begin
Client�ε�ǽ�θƽ�
=end

    #
    # �����С��饤�ɤ���뤳�Ȥ����Ԥ����᥽�å�
    #

    def main 
=begin
�ᥤ��
=end
    end
    def terminate 
=begin
��߽���
=end
    end
  end

  class ActiveAgent < Agent
    attr_reader(:thread)
=begin
���Υ���������ȤΥ���å�:Thread
=end
    attr_reader(:message_queue)
=begin
��å��������塼:Queue
nil�ΤȤ�����������ݤ��Ƥ��뤳�Ȥ򼨤�
=end
    attr_reader(:log_queue)
=begin
�����塼:Queue
nil�ΤȤ�����������ݤ��Ƥ��뤳�Ȥ򼨤�
=end

    def start(client)
=begin
��ư
=end
      @client = client
      @thread = Thread.current
      putlog("start", "started.")
      # ǽưŪ��ư��
      begin
	main
      rescue Stop
	# ��߽���
	terminate
      end
    end
    def stop 
=begin
���
=end
      @thread.raise(Stop.new)
      super
    end
    # 
    def evolve
    end
  end

  class PassiveAgent < Agent
    #
#    def start(client)
#      super
#      # ����¾�ν��������
#      # �֥�å�������return���ʤ��ƤϤʤ�ʤ���
#    end
    def notifyMessage(msg)
=begin
��å�������������
���������ƤΥ�å����������Τ�����
=end
    end
    def notifyLog(log)
=begin
����������
���������ƤΥ������Τ�����
=end
    end
  end

  class TemporaryAgent < Agent
    def start(client)
      super
      # ���Ū�ʽ���
      # �֥�å�������return���ʤ��ƤϤʤ�ʤ���
    end
  end
end

