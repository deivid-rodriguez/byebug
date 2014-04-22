module SetTest
  class SetTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 2
        a += 1
      end
    end

    [:autoeval, :autolist, :autoreload, :autosave, :basename, :forcestep,
     :fullpath, :post_mortem, :stack_on_error, :testing, :linetrace,
     :tracing_plus].each do |setting|
      describe "setting boolean #{setting} to on" do
        temporary_change_hash Byebug::Setting, setting, false

        it "must set #{setting} to on using on" do
          enter "set #{setting} on"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end

        it "must set #{setting} to on using 1" do
          enter "set #{setting} 1"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end

        it "must set #{setting} to on by default" do
          enter "set #{setting}"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end
      end

      describe "setting boolean #{setting} to off" do
        temporary_change_hash Byebug::Setting, setting, true

        it "must set #{setting} to off using off" do
          enter "set #{setting} off"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end

        it "must set #{setting} to on using 0" do
          enter "set #{setting} 0"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end

        it "must set #{setting} to off using 'no' prefix" do
          enter "set no#{setting}"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end
      end
    end

    describe 'shortcuts' do
      describe 'setting' do
        temporary_change_hash Byebug::Setting, :autosave, false

        it 'must set setting if shortcut not ambiguous' do
          enter 'set autos'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal true
        end

        it 'must not set setting if shortcut is ambiguous' do
          enter 'set auto'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal false
        end
      end

      describe 'unsetting' do
        temporary_change_hash Byebug::Setting, :autosave, true

        it 'must unset setting if shortcut not ambiguous' do
          enter 'set noautos'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal false
        end

        it 'must not set setting to off if shortcut ambiguous' do
          enter 'set noauto'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal true
        end
      end
    end

    describe 'testing' do
      describe 'state' do
        describe 'when setting "testing" to on' do
          temporary_change_hash Byebug::Setting, :testing, false

          it 'must get set' do
            enter 'set testing', 'break 7', 'cont'
            debug_proc(@example) {
              state.must_be_kind_of Byebug::CommandProcessor::State }
          end
        end

        describe 'when setting "testing" to off' do
          temporary_change_hash Byebug::Setting, :testing, true

          it 'must get unset' do
            enter 'set notesting', 'break 7', 'cont'
            debug_proc(@example) { state.must_be_nil }
          end
        end
      end
    end

    describe 'histsize' do
      temporary_change_hash Byebug::Setting, :histsize, 1

      it 'must set maximum history size' do
        enter 'set histsize 250'
        debug_proc(@example)
        Byebug::Setting[:histsize].must_equal 250
      end

      it 'must show a message' do
        enter 'set histsize 250'
        debug_proc(@example)
        check_output_includes "Maximum size of byebug's command history is 250"
      end

      it 'must show an error message if no size provided' do
        enter 'set histsize'
        debug_proc(@example)
        check_output_includes 'You must specify a value for setting :histsize'
      end
    end

    describe 'histfile' do
      let(:filename) { File.expand_path('.custom-byebug-hist') }

      temporary_change_hash Byebug::Setting, :histfile, File.expand_path('.byebug-hist')

      it 'must set history filename' do
        enter "set histfile #{filename}"
        debug_proc(@example)
        Byebug::Setting[:histfile].must_equal filename
      end

      it 'must show a message' do
        enter "set histfile #{filename}"
        debug_proc(@example)
        check_output_includes "The command history file is #{filename}"
      end

      it 'must show an error message if no filename provided' do
        enter 'set histfile'
        debug_proc(@example)
        check_output_includes 'You must specify a value for setting :histfile'
      end
    end

    [:listsize, :width].each do |setting|
      describe "setting integer setting #{setting}" do
        temporary_change_hash Byebug::Setting, setting, 80

        it 'must get correctly set' do
          enter "set #{setting} 120"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal 120
        end
      end
    end

    describe 'Help' do
      it 'must show help when typing just "set"' do
        enter 'set', 'cont'
        debug_proc(@example)
        check_output_includes(/Modifies parts of byebug environment./)
        check_output_includes(/List of settings supported in byebug/)
      end
    end
  end
end
