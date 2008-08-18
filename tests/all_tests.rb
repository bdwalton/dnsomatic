#!/usr/bin/ruby -w
#
require 'test/unit'

Dir.glob("test*rb") do |f|
  require "#{f.sub(/\.rb/, '')}"
end


