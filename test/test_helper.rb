require 'minitest/autorun'
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
