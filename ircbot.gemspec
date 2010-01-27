# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ircbot}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["maiha"]
  s.date = %q{2010-01-27}
  s.default_executable = %q{ircbot}
  s.description = %q{An irc bot framework that offers easy-to-use by plugins}
  s.email = %q{maiha@wota.jp}
  s.executables = ["ircbot"]
  s.extra_rdoc_files = ["README", "MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README", "Rakefile", "lib/ircbot", "lib/ircbot/framework.rb", "lib/ircbot/client.rb", "lib/ircbot/client", "lib/ircbot/client/config.rb", "lib/ircbot/client/config", "lib/ircbot/client/config/channels.rb", "lib/ircbot/client/config/plugins.rb", "lib/ircbot/client/config/generator.rb", "lib/ircbot/client/encoding.rb", "lib/ircbot/client/core.rb", "lib/ircbot/client/commands.rb", "lib/ircbot/client/standalone.rb", "lib/ircbot/client/plugins.rb", "lib/ircbot/client/logger.rb", "lib/ircbot/client/eventable.rb", "lib/ircbot/client/timeout.rb", "lib/ircbot/core_ext", "lib/ircbot/core_ext/extending.rb", "lib/ircbot/core_ext/message.rb", "lib/ircbot/core_ext/delegation.rb", "lib/ircbot/plugins.rb", "lib/ircbot/version.rb", "lib/ircbot/plugin.rb", "lib/ircbot.rb", "spec/config_spec.rb", "spec/plugin_spec.rb", "spec/provide_helper.rb", "spec/fixtures", "spec/fixtures/sama-zu.yml", "spec/its_helper.rb", "spec/spec_helper.rb", "spec/framework_spec.rb", "spec/plugins_spec.rb", "plugins/tv.rb", "plugins/reminder.rb", "plugins/echo.rb", "plugins/plugins.rb", "plugins/which.rb", "plugins/irc.rb", "config/wota.yml", "config/airi.yml", "config/sama-zu.yml", "config/yml.erb", "bin/ircbot"]
  s.homepage = %q{http://github.com/maiha/ircbot}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{asakusarb}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{easy irc bot framework}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<extlib>, [">= 0.9.14"])
      s.add_runtime_dependency(%q<net-irc>, [">= 0.0.9"])
    else
      s.add_dependency(%q<extlib>, [">= 0.9.14"])
      s.add_dependency(%q<net-irc>, [">= 0.0.9"])
    end
  else
    s.add_dependency(%q<extlib>, [">= 0.9.14"])
    s.add_dependency(%q<net-irc>, [">= 0.0.9"])
  end
end
