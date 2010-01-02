=begin header
localization extension
  IO supporting coding system conversion

  $Author: igarashi $
  $Date: 2001/01/02 00:21:18 $

  Copyright (C) 1998-2001 Hiroshi IGARASHI
=end

require 'kconv'
#require 'uconv'

$vsave, $VERBOSE = $VERBOSE, FALSE

module Kernel
  private

  def println(*args)
=begin
print with ln
=end
    STDOUT.println(*args)
  end

  def eprint(*args)
=begin
print to stderr
=end
    STDERR.print(*args)
  end

  def eprintln(*args)
=begin
eprint with ln
=end
    STDERR.println(*args)
  end
end

# IO class extension
class IO
  def println(*args)
=begin
print with ln
=end
    if args.length > 0
      print(*args)
    end
    print("\n")
  end
  public(:println)
end

class << ARGF
  def lineno
    $.
  end
  def path
    filename
  end
end

## available only if kconv ext module imported
if defined?(Kconv)

  module Kernel
    private

    # lreadline
    def lreadline(*arg)
      Kconv.tointern(readline(*arg))
    end

    # lgets
    def lgets(*arg)
      ret = gets(*arg)
      unless ret.nil?
	Kconv.tointern(ret)
      else
	nil
      end
    end

    def p(*args)
      args.each { |arg|
	println(Kconv.toextern(arg.inspect))
      }
    end

    # lprint
    def lprint(*args)
      STDOUT.lprint(*args)
    end
  
    # lprint with ln
    def lprintln(*args)
      STDOUT.lprintln(*args)
    end

    # leprint
    def leprint(*args)
      STDERR.lprint(*args)
    end

    def leprintln(*args)
=begin
leprint with ln
=end
      STDERR.lprintln(*args)
    end
  end

  # Kconv module extension
  module Kconv
    ## local encoding
    case $KIOCODE
    ## EUC
    when 'EUC'
      alias_method(:toextern, :toeuc)
    ## JIS
    when 'JIS'
      alias_method(:toextern, :tojis)
    ## SJIS
    when 'SJIS'
      alias_method(:toextern, :tosjis)
    else
      case $KCODE
      ## EUC
      when 'EUC'
	alias_method(:toextern, :toeuc)
      ## JIS
      when 'JIS'
	alias_method(:toextern, :tojis)
      ## SJIS
      when 'SJIS'
	alias_method(:toextern, :tosjis)
      when 'NONE'
	def toextern(str)
	  str
	end
      else
	raise "Unknown coding system(\"#{$KIOCODE}\")."
      end
    end

    case $KCODE
    ## EUC
    when 'EUC'
      alias_method(:tointern, :toeuc)
    ## SJIS
    when 'SJIS'
      alias_method(:tointern, :tosjis)
    when 'NONE'
      def tointern(str)
	str
      end
    else
      raise "Unknown coding system(\"#{$KCODE}\")."
    end

    alias_method(:tolocal, :toextern)
    module_function(:toextern, :tolocal, :tointern)
  end
end

class << ARGF

  if defined?(Kconv)
    # lreadline
    def lreadline(*arg)
      Kconv.tointern(readline(*arg))
    end
    # lgets
    def lgets(*arg)
      ret = gets(*arg)
      unless ret.nil?
	Kconv.tointern(ret)
      else
	nil
      end
    end
  end

end

class IO

  if defined?(Kconv)

    # lreadline
    def lreadline(*arg)
      Kconv.tointern(readline(*arg))
    end

    # lgets
    def lgets(*arg)
      ret = gets(*arg)
      unless ret.nil?
	Kconv.tointern(ret)
      else
	nil
      end
    end

    # convert to local encoding and print 
    def lprint(*args)
      args.each { |arg|
	print(Kconv.toextern(arg.to_s))
      }
    end
    def jisprint(*args)
      args.each { |arg|
	print(Kconv.tojis(arg.to_s))
      }
    end
    def eucprint(*args)
      args.each { |arg|
	print(Kconv.toeuc(arg.to_s))
      }
    end
    def sjisprint(*args)
      args.each { |arg|
	print(Kconv.tosjis(arg.to_s))
      }
    end

    def lprintln(*args)
      lprint(*args)
      print("\n")
    end

    def set_codesys(codesys_name)
      case codesys_name
      ## JIS
      when 'JIS'
	class << self
	  alias_method(:lprint, :jisprint)
	end
      ## EUC
      when 'EUC'
	class << self
	  alias_method(:lprint, :eucprint)
	end
      ## SJIS
      when 'SJIS'
	class << self
	  alias_method(:lprint, :sjisprint)
	end
      when 'NONE'
	alias_method(:lprint, :print)
      else
	raise "Unknown coding system(\"#{codesys_name}\")."
      end
    end
    public(:lreadline, :lprint, :lprintln)
  end
end

$VERBOSE = $vsave
