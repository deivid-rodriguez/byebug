require_relative 'test_helper'

class TestEdit < TestDsl::TestCase

  describe 'open configured editor' do
    temporary_change_hash ENV, 'EDITOR', 'editr'

    it 'must open current file in current line in configured editor' do
      Byebug::Edit.any_instance.expects(:system).
                                with("editr +2 #{fullpath('edit')}")
      enter 'edit'
      debug_file 'edit'
    end
  end

  describe 'open default editor' do
    temporary_change_hash ENV, 'EDITOR', nil

    it 'must call "ex" with current line and file if EDITOR env not set' do
      Byebug::Edit.any_instance.expects(:system).
                                with("ex +2 #{fullpath('edit')}")
      enter 'edit'
      debug_file 'edit'
    end
  end

  describe 'open configured editor specifying line and file' do
    temporary_change_hash ENV, 'EDITOR', 'editr'

    it 'must open specified line in specified file with configured editor' do
      Byebug::Edit.any_instance.expects(:system).
                                with("editr +3 #{fullpath('breakpoint')}")
      enter "edit #{fullpath('breakpoint')}:3"
      debug_file 'edit'
    end
  end

  it 'must show an error if there is no such line' do
    enter "edit #{fullpath('edit3')}:6"
    debug_file 'edit'
    check_output_includes \
      "File \"#{fullpath('edit3')}\" is not readable.", interface.error_queue
  end

  it 'must show an error if there is incorrect syntax' do
    enter 'edit blabla'
    debug_file 'edit'
    check_output_includes \
      'Invalid file/line number specification: blabla', interface.error_queue
  end
end
