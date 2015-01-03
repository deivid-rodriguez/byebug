module Byebug
  #
  # Tests threading functionality.
  #
  class ThreadTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
         1:  module Byebug
         2:    #
         3:    # Toy class to test threading
         4:    #
         5:    class #{example_class}
         6:      attr_accessor :lock
         7:
         8:      def initialize
         9:        @lock = Queue.new
        10:      end
        11:
        12:      def launch
        13:        t1 = Thread.new do
        14:          loop do
        15:            break unless lock.empty?
        16:            sleep 0.01
        17:          end
        18:        end
        19:
        20:        @t2 = Thread.new do
        21:          sleep
        22:        end
        23:
        24:        t1.join
        25:      end
        26:
        27:      def kill
        28:        @t2.kill
        29:      end
        30:    end
        31:
        32:    byebug
        33:
        34:    t = #{example_class}.new
        35:    t.launch
        36:    t.kill
        37:  end
      EOC
    end

    def first_thnum
      Byebug.contexts.first.thnum
    end

    def last_thnum
      Byebug.contexts.last.thnum
    end

    def curr_thnum
      Byebug.contexts.find { |ctx| ctx.thread == Thread.current }.thnum
    end

    def test_thread_list_marks_current_thread_with_a_plus_sign
      thnum, file = nil, example_path
      enter 'cont 13', 'thread list', 'lock << 0'
      debug_code(program) { thnum = first_thnum }

      check_output_includes(/\+ #{thnum} #<Thread:0x\h+ run>\t#{file}:13/)
    end

    def test_thread_list_shows_all_available_threads
      enter 'cont 24', 'thread list', 'lock << 0'
      debug_code(program)

      check_output_includes(/(\+)?\d+ #<Thread:0x\h+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:0x\h+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:0x\h+ (sleep|run)>/)
    end

    def test_thread_stop_marks_thread_as_suspended
      thnum = nil
      enter 'cont 24', -> { "thread stop #{t2_thnum}" }, 'lock << 0'
      debug_code(program) { thnum = t2_thnum }

      check_output_includes(/\$ #{thnum} #<Thread:/)
    end

    def test_thread_stop_actually_suspends_thread_execution
      enter 'cont 24',
            'set linetrace',
            -> { "thread stop #{last_thnum}" },
            'lock << 0'
      debug_code(program)

      check_output_doesnt_include(/Tracing: #{example_path}:21/)
    end

    def test_thread_stop_shows_error_when_thread_number_not_specified
      enter 'cont 13', 'thread stop', 'lock << 0'
      debug_code(program)

      check_error_includes '"thread stop" argument "" needs to be a number'
    end

    def test_thread_stop_shows_error_when_trying_to_stop_current_thread
      enter 'cont 13', -> { "thread stop #{curr_thnum}" }, 'lock << 0'
      debug_code(program)

      check_error_includes "It's the current thread"
    end

    def test_thread_resume_removes_threads_from_the_suspended_state
      thnum = nil
      enter 'cont 24',
            -> { thnum = last_thnum; "thread stop #{thnum}" },
            -> { "thread resume #{thnum}" },
            'lock << 0'

      debug_code(program) do
        assert_equal false, Byebug.contexts.last.suspended?
      end

      check_output_includes(/\$ #{thnum} #<Thread:0x\h+/,
                            /#{thnum} #<Thread:0x\h+/)
    end

    def test_thread_resume_shows_error_if_thread_number_not_specified
      enter 'cont 13', 'thread resume', 'lock << 0'
      debug_code(program)

      check_error_includes '"thread resume" argument "" needs to be a number'
    end

    def test_thread_resume_shows_error_when_trying_to_resume_current_thread
      enter 'cont 13', -> { "thread resume #{first_thnum}" }, 'lock << 0'
      debug_code(program)

      check_error_includes "It's the current thread"
    end

    def test_thread_resume_shows_error_if_thread_is_already_running
      enter 'cont 24', -> { "thread resume #{last_thnum}" }, 'lock << 0'
      debug_code(program)

      check_error_includes 'Already running'
    end

    def test_thread_switch_changes_execution_to_another_thread
      enter 'cont 24', -> { "thread switch #{last_thnum}" }, 'lock << 0'

      debug_code(program) { assert_equal state.line, 21 }
    end

    def test_thread_switch_shows_error_if_thread_number_not_specified
      enter 'cont 13', 'thread switch', 'lock << 0'
      debug_code(program)

      check_error_includes '"thread switch" argument "" needs to be a number'
    end

    def test_thread_switch_shows_error_when_trying_to_switch_current_thread
      enter 'cont 13', -> { "thread switch #{first_thnum}" }, 'lock << 0'
      debug_code(program)

      check_error_includes "It's the current thread"
    end
  end
end
