module ShowTest
  class ShowTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
      end
    end

    [:autoeval, :autoirb, :autoreload, :autosave, :basename, :forcestep,
     :fullpath, :post_mortem, :stack_on_error, :testing, :linetrace,
     :tracing_plus].each do |setting|

      describe "showing disabled boolean setting #{setting}" do
        temporary_change_hash Byebug::Setting, setting, false

        it 'must show default value' do
          enter "show #{setting}"
          debug_proc(@example)
          check_output_includes "#{setting} is off"
        end
      end

      describe "showing enabled boolean setting #{setting}" do
        temporary_change_hash Byebug::Setting, setting, true

        it 'must show default value' do
          enter "show #{setting}"
          debug_proc(@example)
          check_output_includes "#{setting} is on"
        end
      end
    end

    describe 'callstyle' do
      it 'must show default value' do
        enter 'show callstyle'
        debug_proc(@example)
        check_output_includes 'Frame display callstyle is :long'
      end
    end

    describe 'listsize' do
      it 'must show listsize' do
        enter 'show listsize'
        debug_proc(@example)
        check_output_includes 'Number of source lines to list is 10'
      end
    end

    describe 'width' do
      let(:cols) { `stty size`.scan(/\d+/)[1].to_i }

      it 'must show default width' do
        enter 'show width'
        debug_proc(@example)
        check_output_includes "Maximun width of byebug's output is #{cols}"
      end
    end

    describe 'unknown command' do
      it 'must show a message' do
        enter 'show bla'
        debug_proc(@example)
        check_output_includes 'Unknown setting :bla'
      end
    end

    describe 'histfile' do
      before { @filename = Byebug::Setting[:histfile] }

      it 'must show history filename' do
        enter 'show histfile'
        debug_proc(@example)
        check_output_includes "The command history file is #{@filename}"
      end
    end

    describe 'histsize' do
      before { @max_size = Byebug::Setting[:histsize] }

      it "must show history's max size" do
        enter 'show histsize'
        debug_proc(@example)
        check_output_includes \
          "Maximum size of byebug's command history is #{@max_size}"
      end
    end

    describe 'commands' do
      temporary_change_const Readline, 'HISTORY', %w(aaa bbb ccc ddd)

      describe 'with history disabled' do
        temporary_change_hash Byebug::Setting, :autosave, false

        it 'must not show records from readline' do
          skip 'for now'
          enter 'show commands'
          debug_proc(@example)
          check_output_includes "Not currently saving history. " \
                                'Enable it with "set autosave"'
        end
      end

      describe 'with history enabled' do
        temporary_change_hash Byebug::Setting, :autosave, true

        describe 'show records' do
          it 'displays last max_size records from readline history' do
            skip 'for now'
            enter 'set histsize 3', 'show commands'
            debug_proc(@example)
            check_output_includes(/2  bbb\n    3  ccc\n    4  ddd/)
            check_output_doesnt_include(/1  aaa/)
          end
        end

        describe 'max records' do
          it 'displays whole history if max_size is bigger than Readline::HISTORY' do
            skip 'for now'
            enter 'set histsize 7', 'show commands'
            debug_proc(@example)
            check_output_includes(/1  aaa\n    2  bbb\n    3  ccc\n    4  ddd/)
          end
        end

        describe 'with specified size' do
          it 'displays the specified number of entries most recent first' do
            skip 'for now'
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
        check_output_includes(/Generic command for showing byebug settings./)
        check_output_includes(/List of settings supported in byebug/)
      end
    end
  end
end
