module Byebug
  class RestartExample
    def concat_args(a, b, c)
      a.to_s + b.to_s + c.to_s
    end
  end

  class RestartTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = ARGV[0]
        b = ARGV[1]
        c = ARGV[2]
        RestartExample.new.concat_args(a, b, c)
      end

      @old_prog_script = Byebug::PROG_SCRIPT if defined?(Byebug::PROG_SCRIPT)

      super
    end

    def after
      force_set_const(Byebug, 'PROG_SCRIPT', @old_prog_script)
    end

    def must_restart(cmd = nil)
      expectation = RestartCommand.any_instance.expects(:exec)
      expectation = expectation.with(cmd) if cmd
      expectation
    end

    def test_restarts_with_manual_arguments
      force_set_const(Byebug, 'BYEBUG_SCRIPT', 'byebug_script')
      cmd = "#{BYEBUG_SCRIPT} #{PROG_SCRIPT} 1 2 3"
      must_restart(cmd)
      enter 'restart 1 2 3'
      debug_proc(@example)
      check_output_includes "Re exec'ing:\n\t#{cmd}"
    end

    def test_does_not_restart_when_no_script_specified
      force_unset_const(Byebug, 'PROG_SCRIPT')
      must_restart.never
      enter 'restart'
      debug_proc(@example)
      check_error_includes "Don't know name of debugged program"
    end

    def test_does_not_restart_when_script_specified_does_not_exist
      force_set_const(Byebug, 'PROG_SCRIPT', 'blabla')
      must_restart.never
      enter 'restart'
      debug_proc(@example)
      check_error_includes 'Ruby program blabla doesn\'t exist'
    end

    def test_still_restarts_when_byebug_attached_to_running_program
      force_unset_const(Byebug, 'BYEBUG_SCRIPT')
      must_restart
      enter 'restart'
      debug_proc(@example)
      check_output_includes 'Byebug was not called from the outset...'
      check_output_includes "Ruby program #{PROG_SCRIPT} not executable... " \
                            "We'll wrap it in a ruby call"
    end
  end
end
