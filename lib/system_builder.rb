$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module SystemBuilder
  VERSION = '0.0.3'

  @@configurations = {}
  
  def self.config(name, value = nil, &block)
    value = (value or block.call)
    puts "* load configuration #{name}"
    @@configurations[name.to_s] = value
  end

  def self.configuration(name)
    @@configurations[name.to_s]
  end

end

require 'system_builder/core_ext'
require 'system_builder/image'
require 'system_builder/boot'
require 'system_builder/configurator'
