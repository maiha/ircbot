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
    text.strip.gsub(/^#{config.nick}\./) {
      command, arg = $'.split(/\s+/,2)
      arg = arg.to_s.strip

      case command.to_s
      when "load", "register"
        plugins.load arg
        throw :halt, "Loaded #{arg}"

      when "delete", "remove"
        plugins.delete arg
        throw :halt, "Removed #{arg}"

      when "start"
        plugins.start arg
        throw :halt, "Started #{arg}"

      when "stop"
        plugins.stop arg
        throw :halt, "Stopped #{arg}"

      when "help"
        if arg.empty?
          throw :halt, [bot_help, plugins_help].join("\n")
        else
          throw :halt, plugins[arg].help
        end
      end
    }
    return nil
  end

  private
    def plugins_help
      "plugins: %s" % plugins.map(&:to_s).join(', ')
    end

    def bot_help
      config.help ||
        "%s bot [%s (ver:%s)]" % [config.nick, Ircbot::HOMEPAGE, Ircbot::VERSION]
    end
end

