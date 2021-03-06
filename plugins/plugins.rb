#!/usr/bin/env ruby

require 'rubygems'
require 'ircbot'

class PluginsPlugin < Ircbot::Plugin
  def help
    <<-EOF
[control plugins]
usage: #{config.nick}.COMMANDS [PLUGIN_NAME]
commands: load, start, stop, delete
#{plugins_help}
    EOF
  end

  def reply(text)
    if me?
      case command
      when "load"
        plugins.load arg
        done "Loaded #{arg}"

      when "delete", "remove"
        plugins.delete arg
        done "Removed #{arg}"

      when "start"
        plugins.start arg
        done "Started #{arg}"

      when "stop"
        plugins.stop arg
        done "Stopped #{arg}"

      when "help"
        if arg.empty?
          done [config_help, plugins_help, bot_help].compact.join("\n")
        else
          done plugins[arg].help
        end
      end
    end
    return nil
  end

  private
    def plugins_help
      "plugins: %s" % plugins.map(&:to_s).join(', ')
    end

    def bot_help
      "%s bot [%s (ver:%s)]" % [config.nick, Ircbot::HOMEPAGE, Ircbot::VERSION]
    end

    def config_help
      config.help
    end
end

