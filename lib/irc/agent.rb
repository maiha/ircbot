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
IRC上で動作するagentの枠組みを提供するクラス。
派生し、メソッドをoverrideして利用する
=end

    include Constants

    #attr_reader(:name)
    attr_accessor(:name)
=begin
エージェント名(スクリプト名と1対1対応):String
=end
    attr_reader(:nick)
=begin
エージェント名:String
=end
    attr_reader(:timestamp)
=begin
生成時刻:Time
=end
    attr_accessor(:script_name)
=begin
生成元スクリプトファイル名:String
=end

    def initialize(nick=__id__.to_s)
=begin
生成のみ行う（実際の初期化はstartで行う）
=end
      @nick = nick
      @timestamp = Time.now
    end
    def start(client)
=begin
初期化・起動
  client:Client このAgentが組み込まれるClientオブジェクト
=end
      @client = client
      putlog("start", "started.")
      main
    end
    def restart(old_agent)
=begin
再起動
  old_agent:Agent nilならば現在の状態のまま動作開始
=end
    end
    def stop
=begin
停止
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
Clientの機能の呼出
=end

    #
    # オーバーライドされることが期待されるメソッド
    #

    def main 
=begin
メイン
=end
    end
    def terminate 
=begin
停止処理
=end
    end
  end

  class ActiveAgent < Agent
    attr_reader(:thread)
=begin
このエージェントのスレッド:Thread
=end
    attr_reader(:message_queue)
=begin
メッセージキュー:Queue
nilのとき受け取りを拒否していることを示す
=end
    attr_reader(:log_queue)
=begin
ログキュー:Queue
nilのとき受け取りを拒否していることを示す
=end

    def start(client)
=begin
起動
=end
      @client = client
      @thread = Thread.current
      putlog("start", "started.")
      # 能動的な動作
      begin
	main
      rescue Stop
	# 停止処理
	terminate
      end
    end
    def stop 
=begin
停止
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
#      # その他の初期化処理
#      # ブロックせずにreturnしなくてはならない。
#    end
    def notifyMessage(msg)
=begin
メッセージ到着通知
（当面全てのメッセージが通知される）
=end
    end
    def notifyLog(log)
=begin
ログ到着通知
（当面全てのログが通知される）
=end
    end
  end

  class TemporaryAgent < Agent
    def start(client)
      super
      # 一時的な処理
      # ブロックせずにreturnしなくてはならない。
    end
  end
end

