module ShowTest
  class ShowTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
      end
    end

    describe 'autolist' do
      it 'must show default value' do
        enter 'show autolist'
        debug_proc(@example)
        check_output_includes 'autolist is on.'
      end
    end

    describe 'autoeval' do
      it 'must show default value' do
        enter 'show autoeval'
        debug_proc(@example)
        check_output_includes 'autoeval is on.'
      end
    end

    describe 'autoreload' do
      it 'must show default value' do
        enter 'show autoreload'
        debug_proc(@example)
        check_output_includes 'autoreload is on.'
      end
    end

    describe 'autoirb' do
      before { Byebug::IrbCommand.any_instance.stubs(:execute) }

      it 'must show default value' do
        enter 'show autoirb'
        debug_proc(@example)
        check_output_includes 'autoirb is off.'
      end
    end

    describe 'basename' do
      it 'must show default value' do
        enter 'show basename'
        debug_proc(@example)
        check_output_includes 'basename is off.'
      end
    end

    describe 'callstyle' do
      it 'must show default value' do
        enter 'show callstyle'
        debug_proc(@example)
        check_output_includes 'Frame call-display style is long.'
      end
    end

    describe 'forcestep' do
      it 'must show default value' do
        enter 'show forcestep'
        debug_proc(@example)
        check_output_includes 'force-stepping is off.'
      end
    end

    describe 'fullpath' do
      it 'must show default value' do
        enter 'show fullpath'
        debug_proc(@example)
        check_output_includes 'Displaying frame\'s full file names is on.'
      end
    end

    describe 'tracing' do
      it 'must show default value' do
        enter 'show tracing'
        debug_proc(@example)
        check_output_includes 'line tracing is off.'
      end
    end

    describe 'tracing_plus' do
      it 'must show default value' do
        enter 'show tracing_plus'
        debug_proc(@example)
        check_output_includes 'line tracing style is different consecutive lines.'
      end
    end

    describe 'listsize' do
      it 'must show listsize' do
        enter 'show listsize'
        debug_proc(@example)
        check_output_includes 'Number of source lines to list is 10.'
      end
    end

    describe 'stack_on_error' do
      it 'must show stack_on_error' do
        enter 'show stack_on_error'
        debug_proc(@example)
        check_output_includes 'Displaying stack trace is off.'
      end
    end

    describe 'version' do
      it 'must show version' do
        enter 'show version'
        debug_proc(@example)
        check_output_includes "Byebug #{Byebug::VERSION}"
      end
    end

    describe 'width' do
      let(:cols) { `stty size`.scan(/\d+/)[1].to_i }

      it 'must show default width' do
        enter 'show width'
        debug_proc(@example)
        check_output_includes "Width is #{cols}."
      end
    end

    describe 'unknown command' do
      it 'must show a message' do
        enter 'show bla'
        debug_proc(@example)
        check_output_includes 'Unknown show command bla'
      end
    end

    describe 'autosave' do
      it 'must show default value' do
        enter 'show autosave'
        debug_proc(@example)
        check_output_includes 'Saving history is on.'
      end
    end

    describe 'histfile' do
      before { @filename = Byebug::History::DEFAULT_FILE }

      it 'must show history filename' do
        enter 'show histfile'
        debug_proc(@example)
        check_output_includes "The command history file is \"#{@filename}\""
      end
    end

    describe 'histsize' do
      before { @max_size = Byebug::History::DEFAULT_MAX_SIZE }

      it "must show history's max size" do
        enter 'show histsize'
        debug_proc(@example)
        check_output_includes "Byebug history's maximum size is #{@max_size}"
      end
    end

    describe 'commands' do
      temporary_change_const Readline, 'HISTORY', %w(aaa bbb ccc ddd)

      describe 'with history disabled' do
        temporary_change_hash Byebug.settings, :autosave, false

        it 'must not show records from readline' do
          enter 'show commands'
          debug_proc(@example)
          check_output_includes "Not currently saving history. " \
                                'Enable it with "set autosave"'
        end
      end

      describe 'with history enabled' do
        temporary_change_hash Byebug.settings, :autosave, true

        describe 'show records' do
          it 'displays last max_size records from readline history' do
            enter 'set histsize 3', 'show commands'
            debug_proc(@example)
            check_output_includes(/2  bbb\n    3  ccc\n    4  ddd/)
            check_output_doesnt_include(/1  aaa/)
          end
        end

        describe 'max records' do
          it 'displays whole history if max_size is bigger than Readline::HISTORY' do
            enter 'set histsize 7', 'show commands'
            debug_proc(@example)
            check_output_includes(/1  aaa\n    2  bbb\n    3  ccc\n    4  ddd/)
          end
        end

        describe 'with specified size' do
          it 'displays the specified number of entries most recent first' do
            enter 'show commands 2'
            debug_proc(@example)
            check_output_includes(/3  ccc\n    4  ddd/)
            check_output_doesnt_include(/1  aaa\n    2  bbb/)
          end
        end
      end
    end

    describe 'Help' do
      it 'must show help when typing just "show"' do
        enter 'show', 'cont'
        debug_proc(@example)
        check_output_includes(/List of "show" subcommands:/)
      end
    end
  end
end
