# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ircbot}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["maiha"]
  s.date = %q{2010-01-02}
  s.default_executable = %q{ircbot}
  s.description = %q{old fashioned irc bot}
  s.email = %q{maiha@wota.jp}
  s.executables = ["ircbot"]
  s.extra_rdoc_files = ["README", "MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README", "Rakefile", "bin/ircbot"]
  s.homepage = %q{http://github.com/maiha/ircbot}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{asakusarb}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{old fashioned irc bot}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
