require_relative 'support/coverage'

require 'minitest'
require 'mocha/mini_test'

require 'byebug'

require_relative 'support/utils'
require_relative 'support/test_case'
require_relative 'support/printer_helpers'

#
# Load the test files from the command line.
#
argv = ARGV.select do |argument|
  if argument =~ /^-/
    argument
  else
    require File.expand_path argument
    false
  end
end

#
# Run the tests
#
exit Minitest.run(argv)
