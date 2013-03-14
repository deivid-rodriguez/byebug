require 'pathname'
require 'minitest/autorun'
require 'mocha/setup'

require 'byebug'
Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each { |f| require f }

Byebug::Command.settings[:byebugtesting] = true
Byebug.annotate = 2
