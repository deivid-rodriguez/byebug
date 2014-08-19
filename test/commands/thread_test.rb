module Byebug
  class ThreadExample
    def initialize
      Thread.main[:should_break] = false
    end

    def launch
      @t1 = Thread.new do
        while true
          break if Thread.main[:should_break]
          sleep 0.02
        end
      end

      @t2 = Thread.new do
        while true
          sleep 0.02
        end
      end

      @t1.join
      Thread.main[:should_break]
    end

    def kill
      @t2.kill
    end
  end

  class ThreadTestCase < TestCase
    def setup
      @example = -> do
        byebug

        t = ThreadExample.new
        t.launch
        t.kill
      end

      super
    end

    def release
      @release ||= 'eval Thread.main[:should_break] = true'
    end

    def first_thnum
      Byebug.contexts.first.thnum
    end

    def last_thnum
      Byebug.contexts.last.thnum
    end

    def test_thread_list_marks_current_thread_with_a_plus_sign
      skip 'for now'
      thnum = nil
      enter 'break 8', 'cont', 'thread list', release
      debug_proc(@example) { thnum = first_thnum }
      check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:8/)
    end

    def test_thread_list_works_with_shortcut
      skip 'for now'
      thnum = nil
      enter 'break 8', 'cont', 'th list', release
      debug_proc(@example) { thnum = first_thnum }
      check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{__FILE__}:8/)
    end

    def test_thread_list_show_all_available_threads
      skip 'for now'
      enter 'break 21', 'cont', 'thread list', release
      debug_proc(@example)
      check_output_includes(/(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
                            /(\+)?\d+ #<Thread:\S+ (sleep|run)>/)
    end

    def test_thread_stop_marks_thread_as_suspended
      skip 'for now'
      thnum = nil
      enter 'break 21', 'cont', -> { "thread stop #{last_thnum}" }, release
      debug_proc(@example) { thnum = last_thnum }
      check_output_includes(/\$ #{thnum} #<Thread:/)
    end

    def test_thread_stop_actually_suspends_thread_execution
      skip 'for now'
      enter 'break 21', 'cont', 'trace on',
            -> { "thread stop #{last_thnum}" }, release
      debug_proc(@example)
      check_output_doesnt_include(/Tracing: #{__FILE__}:16/,
                                  /Tracing: #{__FILE__}:17/)
    end

    def test_thread_stop_shows_error_when_thread_number_not_specified
      skip 'for now'
      enter 'break 8', 'cont', 'thread stop', release
      debug_proc(@example)
      check_error_includes '"thread stop" needs a thread number'
    end

    def test_thread_stop_shows_error_when_trying_to_stop_current_thread
      skip 'for now'
      enter 'break 8', 'cont', -> { "thread stop #{first_thnum}" }, release
      debug_proc(@example)
      check_error_includes "It's the current thread"
    end

    def test_thread_resume_removes_threads_from_the_suspended_state
      skip 'for now'
      thnum = nil
      enter 'break 21', 'cont',
            -> { thnum = last_thnum ; "thread stop #{thnum}" },
            -> { "thread resume #{thnum}" }, release
      debug_proc(@example) do
        assert_equal false, Byebug.contexts.last.suspended?
      end
      check_output_includes(/\$ #{thnum} #<Thread:/, /#{thnum} #<Thread:/)
    end

    def test_thread_resume_shows_error_if_thread_number_not_specified
      skip 'for now'
      enter 'break 8', 'cont', 'thread resume', release
      debug_proc(@example)
      check_error_includes '"thread resume" needs a thread number'
    end

    def test_thread_resume_shows_error_when_trying_to_resume_current_thread
      skip 'for now'
      enter 'break 8', 'cont', -> { "thread resume #{first_thnum}" }, release
      debug_proc(@example)
      check_error_includes "It's the current thread"
    end

    def test_thread_resume_shows_error_if_thread_is_already_running
      skip 'for now'
      enter 'break 21', 'cont', -> { "thread resume #{last_thnum}" }, release
      debug_proc(@example)
      check_error_includes 'Already running'
    end

    def test_thread_switch_changes_execution_to_another_thread
      skip 'for now'
      enter 'break 21', 'cont', -> { "thread switch #{last_thnum}" }, release
      debug_proc(@example) { assert_equal state.line, 16 }
    end

    def test_thread_switch_shows_error_if_thread_number_not_specified
      skip 'for now'
      enter 'break 8', 'cont', 'thread switch', release
      debug_proc(@example)
      check_error_includes '"thread switch" needs a thread number'
    end

    def test_thread_switch_shows_error_when_trying_to_switch_current_thread
      skip 'for now'
      enter 'break 8', 'cont', -> { "thread switch #{first_thnum}" }, release
      debug_proc(@example)
      check_error_includes "It's the current thread"
    end
  end
end
