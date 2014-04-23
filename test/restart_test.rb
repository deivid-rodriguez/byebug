module RestartTest
  class Example
    def concat_args(a, b, c)
      a.to_s + b.to_s + c.to_s
    end
  end

  class RestartTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = ARGV[0]
        b = ARGV[1]
        c = ARGV[2]
        Example.new.concat_args(a, b, c)
      end
    end

    def must_restart(cmd = nil)
      expectation = Byebug::RestartCommand.any_instance.expects(:exec)
      expectation = expectation.with(cmd) if cmd
      expectation
    end

    describe 'usual restarting' do
      temporary_change_const Byebug, 'BYEBUG_SCRIPT', 'byebug_script'

      it 'must be restarted with arguments' do
        cmd = "#{Byebug::BYEBUG_SCRIPT} #{Byebug::PROG_SCRIPT} 1 2 3"
        must_restart(cmd)
        enter 'restart 1 2 3'
        debug_proc(@example)
        check_output_includes "Re exec'ing:\n\t#{cmd}"
      end
    end

    describe 'no script specified' do
      temporary_change_const Byebug, 'PROG_SCRIPT', :__undefined__

      it 'must not restart and show error messages instead' do
        must_restart.never
        enter 'restart'
        debug_proc(@example)
        check_error_includes 'Don\'t know name of debugged program'
      end
    end

    describe 'no script at the specified path' do
      temporary_change_const Byebug, 'PROG_SCRIPT', 'blabla'

      it 'must not restart' do
        must_restart.never
        enter 'restart'
        debug_proc(@example)
      end

      it 'must show an error message' do
        enter 'restart'
        debug_proc(@example)
        check_error_includes 'Ruby program blabla doesn\'t exist'
      end
    end

    describe 'when no runner script specified' do
      temporary_change_const Byebug, 'BYEBUG_SCRIPT', :__undefined__

      describe 'restarting' do
        before do
          must_restart
          enter 'restart'
        end

        it 'must restart anyways' do
          debug_proc(@example)
        end

        it 'must show a warning message' do
          debug_proc(@example)
          check_output_includes 'Byebug was not called from the outset...'
        end

        it 'must show a warning message when prog script is not executable' do
          debug_proc(@example)
          check_output_includes "Ruby program #{Byebug::PROG_SCRIPT} not " \
                                "executable... We'll wrap it in a ruby call"
        end
      end
    end
  end
end
