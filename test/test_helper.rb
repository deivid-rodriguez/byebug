require 'rubygems'
require 'pathname'
require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/setup'
require 'byebug'

Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each { |f| require f }

# General settings for all tests
Byebug::Command.settings[:byebugtesting] = true
Byebug.annotate = 2
