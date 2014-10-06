module Byebug
  #
  # Tests basic stepping behaviour.
  #
  class BasicSteppingTestCase < TestCase
    def setup
      @example = <<-EOC
         1:  #
         2:  # Toy class to test stepping.
         3:  #
         4:  class BasicSteppingExample
         5:    def self.add_four(num)
         6:      num += 4
         7:      num
         8:    end
         9:  end
        10:
        11:  byebug
        12:
        13:  res = BasicSteppingExample.add_four(7)
        14:
        15:  res
      EOC

      super
    end

    def test_next_goes_to_the_next_line
      enter 'next'
      debug_code(@example) { assert_equal 15, state.line }
    end

    def test_n_goes_to_the_next_line
      enter 'n'
      debug_code(@example) { assert_equal 15, state.line }
    end

    def test_step_goes_to_the_next_statement
      enter 'step'
      debug_code(@example) { assert_equal 6, state.line }
    end

    def test_s_goes_to_the_next_statement
      enter 's'
      debug_code(@example) { assert_equal 6, state.line }
    end

    def test_next_does_not_stop_at_byebug_internal_frames
      enter 'set forcestep', 'next 2'
      debug_code(@example) do
        refute_match(/byebug.test.support/, state.file)
      end
    end
  end

  #
  # Tests advanced stepping behaviour.
  #
  class AdvancedSteppingTestCase < TestCase
    def setup
      @example = <<-EOC
         1:  #
         2:  # Toy class to test advanced stepping.
         3:  #
         4:  class AdvancedSteppingExample
         5:    def self.add_three(num)
         6:      byebug
         7:      num += 2 ; num += 1
         8:      num
         9:    end
        10:  end
        11:
        12:  res = AdvancedSteppingExample.add_three(7)
        13:
        14:  res
      EOC

      super
    end

    %w(next step).each do |cmd|
      define_method(:"test_#{cmd}_stays_by_default") do
        enter cmd
        debug_code(@example) { assert_equal 7, state.line }
      end

      define_method(:"test_#{cmd}+_goes_to_next_line") do
        enter "#{cmd}+"
        debug_code(@example) { assert_equal 8, state.line }
      end

      define_method(:"test_#{cmd}-_stays") do
        enter "#{cmd}-"
        debug_code(@example) { assert_equal 7, state.line }
      end

      define_method(:"test_#{cmd}_goes_to_next_line_if_forcestep_is_set") do
        enter 'set forcestep', cmd
        debug_code(@example) { assert_equal 8, state.line }
      end

      define_method(:"test_#{cmd}+_goes_to_next_line_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}+"
        debug_code(@example) { assert_equal 8, state.line }
      end

      define_method(:"test_#{cmd}-_stays_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}-"
        debug_code(@example) { assert_equal 7, state.line }
      end
    end
  end

  #
  # Tests step/next with arguments higher than one.
  #
  class MoreThanOneStepTestCase < TestCase
    def setup
      @example = <<-EOC
         1:  #
         2:  # Toy class to test advanced stepping.
         3:  #
         4:  class MoreThanOneStepExample
         5:    def self.add_three(num)
         6:      byebug
         7:      3.times do
         8:        num += 1
         9:      end
        10:      num
        11:    end
        12:  end
        13:
        14:  res = MoreThanOneStepExample.add_three(7)
        15:
        16:  res
      EOC

      super
    end

    def test_next_advances_the_specified_number_of_frame_statements
      enter 'next 2'
      debug_code(@example) { assert_equal 16, state.line }
      check_output_includes \
          'Next went up a frame because previous frame finished'
    end

    def step_goes_the_specified_number_of_statements_forward_by_default
      enter 'step 2'
      debug_code(@example) { assert_equal 8, state.line }
    end
  end

  #
  # Tests step/next behaviour in rescue clauses.
  #
  class SteppingRescueTestCase < TestCase
    def setup
      @example = <<-EOC
         1:  #
         2:  # Toy class to test stepping and rescue interaction.
         3:  #
         4:  class SteppingRescueExample
         5:    def self.raise_from_c
         6:      unknown
         7:    rescue NameError
         8:      1
         9:    end
        10:
        11:    def self.raise_from_ruby
        12:      fails_badly
        13:    rescue
        14:      1
        15:    end
        16:
        17:    def self.fails_badly
        18:      fail 'booooooooooooooom'
        19:    end
        20:  end
        21:
        22:  byebug
        23:
        24:  res = SteppingRescueExample.raise_from_c
        25:
        26:  res += SteppingRescueExample.raise_from_ruby
        27:
        28:  res
      EOC

      super
    end

    def test_next_steps_over_rescue_when_raising_from_c_method
      enter 'break SteppingRescueExample.raise_from_c', 'cont', 'next 2'
      debug_code(@example) { assert_equal 8, state.line }
    end

    def test_next_steps_over_rescue_when_raising_from_ruby_method
      enter 'break SteppingRescueExample.raise_from_ruby', 'cont', 'next 2'
      debug_code(@example) { assert_equal 14, state.line }
    end
  end

  #
  # Tests step/next behaviour in combination with backtrace commands.
  #
  class SteppingBacktracesTestCase < TestCase
    def setup
      @example = <<-EOC
         1:  #
         2:  # Toy class to test the combination of "up" and "next" commands.
         3:  #
         4:  class SteppingBacktracesExample
         5:    def a
         6:      byebug
         7:      r = b
         8:      r + 1
         9:    end
        10:
        11:    def b
        12:      r = 2
        13:      r + 1
        14:    end
        15:  end
        16:
        17:  SteppingBacktracesExample.new.a
      EOC

      super
    end

    def test_step_the_up_then_next_advances_in_the_upper_frame
      enter 'step', 'up', 'next'
      debug_code(@example) { assert_equal 8, state.line }
    end
  end
end
