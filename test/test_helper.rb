if ENV['CI']
  require 'coveralls'
  Coveralls.wear! do
    add_filter 'test'
  end
end

require 'minitest'
require 'minitest/spec'
require 'pathname'
require 'mocha/mini_test'
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

# Load the test files from the command line.
argv = ARGV.select do |argument|
  case argument
  when /^-/ then
    argument
  when /\*/ then
    Dir.glob('test/*_test.rb').each do |file|
      require File.expand_path file
    end
    false
  else
    require File.expand_path argument
    false
  end
end

ARGV.replace argv

# Run the tests
Minitest.run
