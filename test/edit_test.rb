module EditTest
  class EditTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        Object.new
      end
    end

    describe 'open configured editor' do
      temporary_change_hash ENV, 'EDITOR', 'editr'

      it 'must open current file in current line in configured editor' do
        file = __FILE__
        Byebug::EditCommand.any_instance.expects(:system).with("editr +6 #{file}")
        enter 'edit'
        debug_proc(@example)
      end
    end

    describe 'open default editor' do
      temporary_change_hash ENV, 'EDITOR', nil

      it 'must call "vim" with current line and file if EDITOR env not set' do
        file = __FILE__
        Byebug::EditCommand.any_instance.expects(:system).with("vim +6 #{file}")
        enter 'edit'
        debug_proc(@example)
      end
    end

    describe 'open configured editor specifying line and file' do
      temporary_change_hash ENV, 'EDITOR', 'editr'

      it 'must open specified line in specified file with configured editor' do
        file = File.expand_path('test/test_helper.rb')
        Byebug::EditCommand.any_instance.expects(:system).with("editr +3 #{file}")
        enter "edit #{file}:3"
        debug_proc(@example)
      end
    end

    it 'must show an error if there is no such file' do
      enter "edit no_such_file:6"
      debug_proc(@example)
      check_error_includes 'File "no_such_file" is not readable.'
    end

    it 'must show an error if there is incorrect syntax' do
      enter 'edit blabla'
      debug_proc(@example)
      check_error_includes 'Invalid file[:line] number specification: blabla'
    end
  end
end
