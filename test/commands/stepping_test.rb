module Byebug
  #
  # Tests basic stepping behaviour.
  #
  class BasicSteppingTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test stepping.
         4:    #
         5:    class TestExample
         6:      def self.add_four(num)
         7:        num += 4
         8:        num
         9:      end
        10:    end
        11:
        12:    byebug
        13:
        14:    res = TestExample.add_four(7)
        15:
        16:    res + 1
        17:  end
      EOC
    end

    def test_next_goes_to_the_next_line
      enter 'next'
      debug_code(program) { assert_equal 16, state.line }
    end

    def test_n_goes_to_the_next_line
      enter 'n'
      debug_code(program) { assert_equal 16, state.line }
    end

    def test_step_goes_to_the_next_statement
      enter 'step'
      debug_code(program) { assert_equal 7, state.line }
    end

    def test_s_goes_to_the_next_statement
      enter 's'
      debug_code(program) { assert_equal 7, state.line }
    end

    def test_next_does_not_stop_at_byebug_internal_frames
      enter 'next 2'
      debug_code(program) do
        refute_match(/byebug.test.support/, state.file)
      end
    end
  end

  #
  # Tests advanced stepping behaviour.
  #
  class AdvancedSteppingTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test advanced stepping.
         4:    #
         5:    class TestExample
         6:      def self.add_three(num)
         7:        byebug
         8:        num += 2 ; num += 1
         9:        num
        10:      end
        11:    end
        12:
        13:    TestExample.add_three(7)
        14:  end
      EOC
    end

    %w(next step).each do |cmd|
      define_method(:"test_#{cmd}_stays_by_default") do
        enter cmd
        debug_code(program) { assert_equal 8, state.line }
      end

      define_method(:"test_#{cmd}+_goes_to_next_line") do
        enter "#{cmd}+"
        debug_code(program) { assert_equal 9, state.line }
      end

      define_method(:"test_#{cmd}-_stays") do
        enter "#{cmd}-"
        debug_code(program) { assert_equal 8, state.line }
      end

      define_method(:"test_#{cmd}_goes_to_next_line_if_forcestep_is_set") do
        enter 'set forcestep', cmd
        debug_code(program) { assert_equal 9, state.line }
      end

      define_method(:"test_#{cmd}+_goes_to_next_line_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}+"
        debug_code(program) { assert_equal 9, state.line }
      end

      define_method(:"test_#{cmd}-_stays_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}-"
        debug_code(program) { assert_equal 8, state.line }
      end
    end
  end

  #
  # Tests step/next with arguments higher than one.
  #
  class MoreThanOneStepTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test advanced stepping.
         4:    #
         5:    class TestExample
         6:      def self.add_three(num)
         7:        byebug
         8:        3.times do
         9:          num += 1
        10:        end
        11:        num
        12:      end
        13:    end
        14:
        15:    res = TestExample.add_three(7)
        16:
        17:    res
        18:  end
      EOC
    end

    def test_next_advances_the_specified_number_of_frame_statements
      enter 'next 2'
      debug_code(program) { assert_equal 17, state.line }
    end

    def step_goes_the_specified_number_of_statements_forward_by_default
      enter 'step 2'
      debug_code(program) { assert_equal 9, state.line }
    end
  end

  #
  # Tests step/next behaviour in rescue clauses.
  #
  class SteppingRescueTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test stepping and rescue interaction.
         4:    #
         5:    class TestExample
         6:      def self.raise_from_c
         7:        unknown
         8:      rescue NameError
         9:        1
        10:      end
        11:
        12:      def self.raise_from_ruby
        13:        fails_badly
        14:      rescue
        15:        1
        16:      end
        17:
        18:      def self.fails_badly
        19:        fail 'booooooooooooooom'
        20:      end
        21:    end
        22:
        23:    byebug
        24:
        25:    TestExample.raise_from_c
        26:    TestExample.raise_from_ruby
        27:  end
      EOC
    end

    def test_next_steps_over_rescue_when_raising_from_c_method
      enter 'break Byebug::TestExample.raise_from_c', 'cont', 'next 2'
      debug_code(program) { assert_equal 9, state.line }
    end

    def test_next_steps_over_rescue_when_raising_from_ruby_method
      enter 'break Byebug::TestExample.raise_from_ruby', 'cont', 'next 2'
      debug_code(program) { assert_equal 15, state.line }
    end
  end

  #
  # Tests step/next behaviour in combination with backtrace commands.
  #
  class SteppingBacktracesTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test the combination of "up" and "next" commands.
         4:    #
         5:    class TestExample
         6:      def a
         7:        byebug
         8:        r = b
         9:        r + 1
        10:      end
        11:
        12:      def b
        13:        r = 2
        14:        r + 1
        15:      end
        16:    end
        17:
        18:    TestExample.new.a
        19:  end
      EOC
    end

    def test_step_the_up_then_next_advances_in_the_upper_frame
      enter 'step', 'up', 'next'
      debug_code(program) { assert_equal 9, state.line }
    end
  end
end
