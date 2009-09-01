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

  def self.sh(*cmd)
    puts "* #{cmd.join(' ')}"
    raise "Command failed: #{$?}" unless system(cmd.join(' '))
  end

  def self.sudo(*cmd)
    sh ["sudo", *cmd]
  end

end
