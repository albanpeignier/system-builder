class Numeric

  def megabytes
    self * 1024 * 1024
  end
  alias_method :megabyte, :megabytes

  def in_megabytes
    self.to_f / 1.megabyte
  end

end

class Object

  def blank?
    false
  end

end

class NilClass 

  def blank?
    true
  end

end

class Array 

  alias_method :blank?, :empty?

end

class String

  alias_method :blank?, :empty?

end

module FileUtils

  def sh(*cmd)
    options = Hash === cmd.last ? cmd.pop : {}
    puts "* #{cmd.join(' ')}"
    raise "Command failed: #{$?}" unless system(cmd.join(' '))
  end
  module_function :sh

  def sudo(*cmd)
    sh ["sudo", *cmd]
  end
  module_function :sudo

end
