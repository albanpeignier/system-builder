$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module SystemBuilder
  VERSION = '0.0.1'
end

require 'system_builder/core_ext'
require 'system_builder/image'
require 'system_builder/boot'
