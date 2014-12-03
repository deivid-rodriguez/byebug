module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTestCase < TestCase
    def program
      strip_line_numbers <<-EOC
        1:  byebug
        2:
        3:  ARGV.join(' ')
      EOC
    end

    def must_restart(cmd = nil)
      expectation = RestartCommand.any_instance.expects(:exec)
      expectation.with(cmd) if cmd
    end

    def test_restarts_with_manual_arguments
      cmd = "ruby -rbyebug -I#{$LOAD_PATH.join(' -I')} test/test_helper.rb 1 2"
      must_restart(cmd)

      enter 'restart 1 2'
      debug_code(program)
      check_output_includes "Re exec'ing:", "\t#{cmd}"
    end

    def test_still_restarts_shows_messages_when_attached_to_running_program
      must_restart
      enter 'restart'

      debug_code(program)
      check_output_includes 'Byebug was not called from the outset...'
      check_output_includes \
        "Program #{Byebug.debugged_program} not executable... " \
        'Wrapping it in a ruby call'
    end
  end
end
