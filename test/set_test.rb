class TestSet < TestDsl::TestCase

  describe 'setting to on' do
    temporary_change_hash Byebug.settings, :autolist, 0

    it 'must set a setting to on' do
      enter 'set autolist on'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 1
    end

    it 'must set a setting to on by 1' do
      enter 'set autolist 1'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 1
    end

    it 'must set a setting to on by default' do
      enter 'set autolist'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 1
    end

    it 'must set a setting using shortcut' do
      enter 'set autol'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 1
    end
  end

  describe 'setting to off' do
    temporary_change_hash Byebug.settings, :autolist, 1

    it 'must set a setting to off' do
      enter 'set autolist off'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 0
    end

    it 'must set a setting to off by 0' do
      enter 'set autolist 0'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 0
    end

    it 'must set a setting to off by "no" prefix' do
      enter 'set noautolist'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 0
    end

    it 'must set a setting to off by "no" prefix and shortcut' do
      enter 'set noautol'
      debug_file 'set'
      Byebug.settings[:autolist].must_equal 0
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

  describe 'history' do
    describe 'save' do
      it 'must set history save to on' do
        enter 'set history save on'
        debug_file 'set'
        interface.history_save.must_equal true
      end

      it 'must set history save to on when no param' do
        enter 'set history save'
        debug_file 'set'
        interface.history_save.must_equal true
      end

      it 'must show a message' do
        enter 'set history save on'
        debug_file 'set'
        check_output_includes 'Saving of history save is on.'
      end

      it 'must set history save to off' do
        enter 'set history save off'
        debug_file 'set'
        interface.history_save.must_equal false
      end
    end

    describe 'size' do
      it 'must set history size' do
        enter 'set history size 250'
        debug_file 'set'
        interface.history_length.must_equal 250
      end

      it 'must show a message' do
        enter 'set history size 250'
        debug_file 'set'
        check_output_includes 'Byebug history size is 250'
      end

      it 'must show an error message if no size provided' do
        enter 'set history size'
        debug_file 'set'
        check_output_includes 'You need to specify the history size'
      end
    end

    describe 'filename' do
      let(:filename) {
        File.join(ENV['HOME']||ENV['HOMEPATH']||'.', '.byebug-hist') }

      it 'must set history filename' do
        enter 'set history filename .byebug-hist'
        debug_file 'set'
        interface.histfile.must_equal filename
      end

      it 'must show a message' do
        enter 'set history filename .byebug-hist'
        debug_file 'set'
        check_output_includes "The command history file is \"#{filename}\""
      end

      it 'must show an error message if no filenmae provided' do
        enter 'set history filename'
        debug_file 'set'
        check_output_includes 'You need to specify a filename'
      end

    end

    it 'must show an error message if used wrong subcommand' do
      enter 'set history bla 2'
      debug_file 'set'
      check_output_includes \
        'Invalid history parameter bla. Should be "filename", "save" or "size"'
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
