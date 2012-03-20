# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "ircbot/version"

Gem::Specification.new do |s|
  s.name        = "ircbot"
  s.version     = Ircbot::VERSION
  s.authors     = ["maiha"]
  s.email       = ["maiha@wota.jp"]
  s.homepage    = Ircbot::HOMEPAGE
  s.summary     = %q{easy irc bot framework}
  s.description = %q{An irc bot framework that offers easy-to-use by plugins}

  s.rubyforge_project = "ircbot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "dsl_accessor", ">= 0.4.0"
  s.add_dependency "extlib", ">= 0.9.14"
  s.add_dependency "net-irc", ">= 0.0.9"

  s.add_development_dependency "rspec", ">= 2.9.0"
end

