module Byebug
  class Example
    def self.a(num)
      num += 2
      b(num)
    end

    def self.b(num)
      v2 = 5 if 1 == num ; [1, 2, v2].map { |t| t.to_f }
      c(num)
    end

    def self.c(num)
      num += 4
      num
    end
  end

  class BasicSteppingTestCase < TestCase
    def setup
      @example = -> do
        byebug

        ex = Example.c(7)
        ex
      end

      super
    end

    def test_next_goes_to_the_next_line
      enter 'next'
      debug_proc(@example) { assert_equal 25, state.line }
    end

    def test_n_goes_to_the_next_line
      enter 'n'
      debug_proc(@example) { assert_equal 25, state.line }
    end

    def test_step_goes_to_the_next_statement
      enter 'step'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_s_goes_to_the_next_statement
      enter 's'
      debug_proc(@example) { assert_equal 14, state.line }
    end

    def test_next_does_not_stop_at_byebug_internal_frames
      enter 'set forcestep', 'next 2'
      debug_proc(@example) { refute_match(/byebug.test.support/, state.file) }
    end
  end

  class AdvancedSteppingTestCase < TestCase
    def setup
      @example = -> do
        byebug

        ex = Example.a(7)
        2.times do
          ex += 1
        end

        Example.b(ex)
      end

      super

      enter 'break 9', 'cont'
    end

    %w(next step).each do |cmd|
      define_method(:"test_#{cmd}_stays_by_default") do
        enter cmd
        debug_proc(@example) { assert_equal 9, state.line }
      end

      define_method(:"test_#{cmd}+_goes_2_next_line") do
        enter "#{cmd}+"
        debug_proc(@example) { assert_equal 10, state.line }
      end

      define_method(:"test_#{cmd}-_stays") do
        enter "#{cmd}-"
        debug_proc(@example) { assert_equal 9, state.line }
      end

      define_method(:"test_#{cmd}_goes_2_next_line_if_forcestep_is_set") do
        enter 'set forcestep', cmd
        debug_proc(@example) { assert_equal 10, state.line }
      end

      define_method(:"test_#{cmd}+_goes_2_next_line_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}+"
        debug_proc(@example) { assert_equal 10, state.line }
      end

      define_method(:"test_#{cmd}-_stays_regardless_forcestep") do
        enter 'set forcestep', "#{cmd}-"
        debug_proc(@example) { assert_equal 9, state.line }
      end
    end

    def test_next_goes_the_specified_number_of_lines_forward_by_default
      enter 'set forcestep', 'next 2'
      debug_proc(@example) { assert_equal 63, state.line }
    end

    def test_next_informs_when_not_staying_in_the_same_frame
      enter 'set forcestep', 'next 2'
      debug_proc(@example)
      check_output_includes \
          'Next went up a frame because previous frame finished'
    end

    def step_goes_the_specified_number_of_statements_forward_by_default
      enter 'set forcestep', 'step 2'
      debug_proc(@example) { assert_equal 63, state.line }
    end

    def test_next_steps_OVER_blocks
      enter 'break 63', 'cont', 'next'
      debug_proc(@example) { assert_equal 67, state.line }
    end

    def test_step_steps_INTO_blocks
      enter 'break 63', 'cont', 'step'
      debug_proc(@example) { assert_equal 64, state.line }
    end
  end

  class RaiseFromCMethodExample
    def a
      b
    rescue NameError
      1
    end

    def b
      c
    end

    def c
      d
    end
  end

  class RaiseFromCMethodTestCase < TestCase
    def test_next_steps_over_rescue_when_raising_from_c_method
      example_raise = -> do
        byebug

        RaiseFromCMethodExample.new.a
      end

      enter 'break 137', 'cont', 'next'
      debug_proc(example_raise) { assert_equal 139, state.line }
    end
  end

  class RaiseFromRubyMethodExample
    def a
      b
    rescue
      1
    end

    def b
      c
    end

    def c
      raise 'bang'
    end
  end

  class RaiseFromRubyMethodTestCase < TestCase
    def test_next_steps_over_rescue_when_raising_from_ruby_method
      example_raise = -> do
        byebug

        RaiseFromRubyMethodExample.new.a
      end

      enter 'break 166', 'cont', 'next'
      debug_proc(example_raise) { assert_equal 168, state.line }
    end
  end
end
