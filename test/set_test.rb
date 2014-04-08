class TestSet < TestDsl::TestCase

  [:autoeval, :autoreload, :autosave, :basename, :forcestep, :fullpath,
   :linetrace_plus, :stack_on_error].each do |setting|

    describe "setting #{setting} to on" do
      temporary_change_hash Byebug.settings, setting, false

      it "must set #{setting} to on using on" do
        enter "set #{setting} on"
        debug_file 'set'
        Byebug.settings[setting].must_equal true
      end

      it "must set #{setting} to on using 1" do
        enter "set #{setting} 1"
        debug_file 'set'
        Byebug.settings[setting].must_equal true
      end

      it "must set #{setting} to on by default" do
        enter "set #{setting}"
        debug_file 'set'
        Byebug.settings[setting].must_equal true
      end

      it "must set #{setting} using shortcut" do
        skip 'it for now until I make it work'
        enter "set autol"
        debug_file 'set'
        Byebug.settings[setting].must_equal 1
      end
    end

    describe "setting #{setting} to off" do
      temporary_change_hash Byebug.settings, setting, true

      it "must set #{setting} to off using off" do
        enter "set #{setting} off"
        debug_file 'set'
        Byebug.settings[setting].must_equal false
      end

      it "must set #{setting} to on using 0" do
        enter "set #{setting} 0"
        debug_file 'set'
        Byebug.settings[setting].must_equal false
      end

      it "must set #{setting} to off using 'no' prefix" do
        enter "set no#{setting}"
        debug_file 'set'
        Byebug.settings[setting].must_equal false
      end

      it "must set #{setting} off using 'no' prefix and shortcut" do
        skip 'it for now until I make it work'
        enter 'set noautol'
        debug_file 'set'
        Byebug.settings[setting].must_equal 0
      end
    end
  end

  describe 'messages' do
    temporary_change_hash Byebug.settings, :autolist, 0

    it 'must show a message after setting' do
      enter 'set autolist on'
      debug_file 'set'
      check_output_includes 'autolist is on.'
    end
  end

  describe 'testing' do
    describe 'state' do
      describe 'when setting "testing" to on' do
        temporary_change_hash Byebug.settings, :testing, false

        it 'must get set' do
          enter 'set testing', 'break 3', 'cont'
          debug_file('set') {
            state.must_be_kind_of Byebug::CommandProcessor::State }
        end
      end

      describe 'when setting "testing" to off' do
        temporary_change_hash Byebug.settings, :testing, true

        it 'must get unset' do
          enter 'set notesting', 'break 3', 'cont'
          debug_file('set') { state.must_be_nil }
        end
      end
    end
  end

  describe 'histsize' do
    after { Byebug::History.max_size = Byebug::History::DEFAULT_MAX_SIZE }

    it 'must set maximum history size' do
      enter 'set histsize 250'
      debug_file 'set'
      Byebug::History.max_size.must_equal 250
    end

    it 'must show a message' do
      enter 'set histsize 250'
      debug_file 'set'
      check_output_includes "Byebug history's maximum size is 250"
    end

    it 'must show an error message if no size provided' do
      enter 'set histsize'
      debug_file 'set'
      check_output_includes 'You need to specify the history size'
    end
  end

  describe 'histfile' do
    let(:filename) { File.expand_path('./.custom-byebug-hist') }

    after { Byebug::History.file = Byebug::History::DEFAULT_FILE }

    it 'must set history filename' do
      enter "set histfile #{filename}"
      debug_file 'set'
      Byebug::History.file.must_equal filename
    end

    it 'must show a message' do
      enter "set histfile #{filename}"
      debug_file 'set'
      check_output_includes "The command history file is \"#{filename}\""
    end

    it 'must show an error message if no filename provided' do
      enter 'set histfile'
      debug_file 'set'
      check_output_includes 'You need to specify a filename'
    end
  end

  describe 'width' do
    temporary_change_hash Byebug.settings, :width, 20

    it 'must get correctly set' do
      enter 'set width 10'
      debug_file('set')
      Byebug.settings[:width].must_equal 10
    end
  end

  describe 'Help' do
    it 'must show help when typing just "set"' do
      enter 'set', 'cont'
      debug_file 'set'
      check_output_includes(/List of "set" subcommands:/)
    end
  end
end
