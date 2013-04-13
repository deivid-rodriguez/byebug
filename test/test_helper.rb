require 'rubygems'
require 'pathname'
require 'minitest/autorun'
require 'mocha/setup'
require 'byebug'

Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each { |f| require f }

Byebug.annotate = 2
