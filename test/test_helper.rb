require 'minitest'
require 'minitest/spec'
require 'pathname'
require 'mocha/setup'
require 'byebug'

Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each { |f| require f }

Byebug.settings[:testing] = true

class DummyObject
  def initialize(*args)
  end
end

# Init globals to avoid warnings
$bla = nil
$binding = binding # this is from irb...

if ARGV.empty?
  Dir.glob(File.expand_path('../*_test.rb', __FILE__)).each { |f| require f }
else
  ARGV.each { |f| require File.expand_path(f) }
end

Minitest.run
