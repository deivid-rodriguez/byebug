module ShowTest
  class ShowTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
      end
    end

    [:autoeval, :autolist, :autoreload, :autosave, :basename, :forcestep,
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
        check_output_includes "Maximum width of byebug's output is #{cols}"
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
