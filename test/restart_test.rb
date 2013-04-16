require_relative 'test_helper'

describe 'Restart Command' do
  include TestDsl

  def must_restart
    Byebug::RestartCommand.any_instance.unstub(:exec)
    Byebug::RestartCommand.any_instance.expects(:exec)
  end

  describe 'usual restarting' do
    before do
      force_set_const Byebug, 'BYEBUG_SCRIPT', 'byebug_script'
    end

    it 'must be restarted with arguments' do
      Byebug::RestartCommand.any_instance.expects(:exec).
        with("#{Byebug::BYEBUG_SCRIPT} 1 2 3")
      enter 'restart 1 2 3'
      debug_file 'restart'
    end

    it 'arguments must be correctly escaped' do
      Byebug::Command.settings[:argv] = ['argv1', 'argv 2']
      Byebug::RestartCommand.any_instance.expects(:exec).with \
        "#{Byebug::BYEBUG_SCRIPT} argv1 argv\\ 2"
      enter 'restart'
      debug_file 'restart'
    end

    it 'must specify arguments by "set" command' do
      Byebug::Command.settings[:argv] = []
      Byebug::RestartCommand.any_instance.expects(:exec).
        with("#{Byebug::BYEBUG_SCRIPT} 1 2 3")
      enter 'set args 1 2 3', 'restart'
      debug_file 'restart'
    end
  end

  describe 'messaging' do
    before { enter 'restart' }

    describe 'reexecing' do
      it 'must restart and show a message about reexecing' do
        force_set_const Byebug, 'BYEBUG_SCRIPT', 'byebug_script'
        Byebug::Command.settings[:argv] = ['argv']
        must_restart
        debug_file 'restart'
        check_output_includes \
          "Re exec'ing:\n\t#{Byebug::BYEBUG_SCRIPT} argv"
      end
    end

    describe 'no script specified and no $0 used instead' do
      before do
        force_unset_const Byebug, 'PROG_SCRIPT'
        force_set_const Byebug,
                        'DEFAULT_START_SETTINGS',
                        init: false, post_mortem: false, tracing: nil
      end

      it 'must not restart and show error messages instead' do
        must_restart.never
        debug_file 'restart'
        check_output_includes 'Don\'t know name of debugged program',
                              interface.error_queue
      end
    end

    describe 'no script specified, $0 used instead' do
      before do
        @old_prog_name = $0
        $0 = 'prog-0'
        force_unset_const Byebug, 'PROG_SCRIPT'
      end
      after { $0 = @old_prog_name }

      it 'must use prog_script from $0 if PROG_SCRIPT is undefined' do
        debug_file 'restart'
        check_output_includes 'Ruby program prog-0 doesn\'t exist',
                              interface.error_queue
      end
    end

    describe 'no script at the specified path' do
      before do
        force_set_const Byebug, 'PROG_SCRIPT', 'blabla'
        force_set_const Byebug,
                        'DEFAULT_START_SETTINGS',
                        init: false, post_mortem: false, tracing: nil
      end

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

    describe 'byebug runner script is not specified' do
      before do
        must_restart
      end

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
      before do
        force_set_const(Byebug, 'INITIAL_DIR', '/unexistent/path')
        must_restart
      end

      it 'must restart anyway' do
        debug_file 'restart'
      end

      it 'must show an error message ' do
        debug_file 'restart'
        check_output_includes \
          'Failed to change initial directory /unexistent/path'
      end
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      skip('No post morten mode for now')
      must_restart
      enter 'cont', 'restart'
      debug_file 'post_mortem'
    end
  end

end
