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

      super
    end

    def must_restart(cmd = nil)
      expectation = RestartCommand.any_instance.expects(:exec)
      expectation = expectation.with(cmd) if cmd
    end

    def test_restarts_with_manual_arguments
      cmd = "ruby -rbyebug -I#{$LOAD_PATH.join(' -I')} test/test_helper.rb 1 2"
      must_restart(cmd)

      enter 'restart 1 2'
      debug_proc(@example)
      check_output_includes "Re exec'ing:\n\t#{cmd}"
    end

    def test_still_restarts_shows_messages_when_attached_to_running_program
      must_restart
      enter 'restart'

      debug_proc(@example)
      check_output_includes 'Byebug was not called from the outset...'
      check_output_includes \
        "Program #{Byebug.debugged_program} not executable... " \
        "Wrapping it in a ruby call"
    end
  end
end
