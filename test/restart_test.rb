class RestartExample
  def concat_args(a, b, c)
    a.to_s + b.to_s + c.to_s
  end
end

class TestRestart < TestDsl::TestCase
  describe 'usual restarting' do
    temporary_change_const Byebug, 'BYEBUG_SCRIPT', 'byebug_script'

    it 'must be restarted with arguments' do
      Byebug::RestartCommand.any_instance.expects(:exec).
        with("#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT} 1 2 3")
      enter 'restart 1 2 3'
      debug_file 'restart'
    end

    describe 'when arguments have spaces' do
      temporary_change_hash Byebug.settings, :argv, ['argv1', 'argv 2']

      it 'must be correctly escaped' do
        Byebug::RestartCommand.any_instance.expects(:exec).with \
          "#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT} argv1 argv\\ 2"
        enter 'restart'
        debug_file 'restart'
      end
    end

    describe 'when arguments specified by set command' do
      temporary_change_hash Byebug.settings, :argv, []

      it 'must specify arguments by "set" command' do
        Byebug::RestartCommand.any_instance.expects(:exec).
          with("#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT} 1 2 3")
        enter 'set args 1 2 3', 'restart'
        debug_file 'restart'
      end
    end
  end

  describe 'messaging' do
    before { enter 'restart' }

    describe 'reexecing' do
      temporary_change_const Byebug, 'BYEBUG_SCRIPT', 'byebug_script'

      describe 'with set args' do
        temporary_change_hash Byebug.settings, :argv, ['argv']

        it 'must restart and show a message about reexecing' do
          must_restart
          debug_file 'restart'
          check_output_includes \
            "Re exec'ing:\n"    \
            "\t#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT} argv"
        end
      end
    end

    describe 'no script specified' do
      temporary_change_const Byebug, 'PROG_SCRIPT', :__undefined__

      describe 'and no $0 used' do
        temporary_change_const Byebug, 'DEFAULT_START_SETTINGS',
          { init: false, post_mortem: false, tracing: nil }

        it 'must not restart and show error messages instead' do
          must_restart.never
          debug_file 'restart'
          check_output_includes 'Don\'t know name of debugged program',
                                interface.error_queue
        end
      end

      describe 'but initialized from $0' do
        it 'must use prog_script from $0' do
          old_prog_name = $0
          $0 = 'prog-0'
          debug_file 'restart'
          check_output_includes 'Ruby program prog-0 doesn\'t exist',
                                interface.error_queue
          $0 = old_prog_name
        end
      end
    end

    describe 'no script at the specified path' do
      temporary_change_const Byebug, 'PROG_SCRIPT', 'blabla'

      describe 'and no restart params set' do
        temporary_change_const Byebug, 'DEFAULT_START_SETTINGS',
          init: false, post_mortem: false, tracing: nil

        it 'must not restart' do
          must_restart.never
          debug_file 'restart'
        end

        it 'must show an error message' do
          debug_file 'restart'
          check_output_includes 'Ruby program blabla doesn\'t exist',
                                interface.error_queue
        end
      end
    end

    describe 'byebug runner script is not specified' do
      before { must_restart }

      it 'must restart anyway' do
        debug_file 'restart'
      end

      it 'must show a warning message' do
        debug_file 'restart'
        check_output_includes 'Byebug was not called from the outset...'
      end

      it 'must show a warning message when prog script is not executable' do
        debug_file 'restart'
        check_output_includes "Ruby program #{Byebug::PROG_SCRIPT} not " \
                              "executable... We'll add a call to Ruby."
      end
    end

    describe 'when can\'t change the dir to INITIAL_DIR' do
      temporary_change_const Byebug, 'INITIAL_DIR', '/unexistent/path'

      it 'must restart anyway' do
        must_restart
        debug_file 'restart'
      end

      it 'must show an error message ' do
        must_restart
        debug_file 'restart'
        check_output_includes \
          'Failed to change initial directory /unexistent/path'
      end
    end
  end
end
