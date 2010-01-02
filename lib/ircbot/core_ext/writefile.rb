#!/usr/local/bin/ruby
#
# writefile.rb
# Author: maiha@wota.jp
# Created: 2002/05/10 14:16:13
# Changed: 2010/01/02 20:42:25

=begin
== usage
  ensure directories of a path exist before open it.

=== syntacs
  File::open!(path, ...)

== sample
  Dir["/tmp/**/*"]			# => []
  File .open!("/tmp/foo/ora", "w+")
  Dir["/tmp/**/*"]			# => ["/tmp/foo", "/tmp/foo/ora"]

== changes
* 2002/06/11 19:45:32
  change interface: open(...,'w!') => open!(...)
=end

def File.open! (path, *args, &block)
  dirname = File.dirname(path) + '/'
  unless File.directory?(dirname)
    dirs = []
    dirname.scan(/\//) {dirs << $`}
    dirs.shift
    dirs.each do |dir|
      unless directory?(dir)
        Dir.mkdir(dir)
      end
    end
  end
  open(path, *args, &block)
end

if $0 == __FILE__
  path = "/tmp/a/b/c.txt"
  File.open!(path, "w+") {|f| f.puts "[OK] Wrote to #{path}"}
  puts File.read(path){}
  File.unlink(path)
end
