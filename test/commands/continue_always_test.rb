require 'test_helper'

module Byebug
  #
  # Tests for continue command
  #
  class ContinueAlwaysTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test continue command.
         4:    #
         5:    class #{example_class}
         6:      def factor(num)
         7:        i=1
         8:        num.times do |new_number|
         9:          i*= new_number
        10:          byebug
        11:        end
        12:      end
        13:    end
        14:    c = 5
        15:
        16:    result = #{example_class}.new.factor(c)
        17:    byebug
        18:    "Result is: " + result.to_s
        19:  end
      RUBY
    end

    def reset_commands
      ContinueAlwaysCommand.always_run = 0
      ListCommand.always_run = 1
    end

    def test_continues_and_never_stop_again
      enter 'continue_always'

      debug_code(program) { assert_program_finished }
      reset_commands
    end

    def test_continues_and_never_stop_using_abbreviation
      enter 'ca'

      debug_code(program) { assert_program_finished }
      reset_commands
    end

    def test_continues_and_never_stop_using_another_abbreviation
      enter 'cont_always'

      debug_code(program) { assert_program_finished }
      reset_commands
    end
  end
end
