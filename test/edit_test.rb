require_relative 'test_helper'

describe 'Edit Command' do
  include TestDsl

  it 'must open an editor with current file and line' do
    temporary_change_hash_value(ENV, 'EDITOR', 'editr') do
      Byebug::Edit.any_instance.expects(:system).
                                with("editr +2 #{fullpath('edit')}")
      enter 'edit'
      debug_file 'edit'
    end
  end

  it 'must open a default editor with current file and line' do
    temporary_change_hash_value(ENV, 'EDITOR', nil) do
      Byebug::Edit.any_instance.expects(:system).
                                with("ex +2 #{fullpath('edit')}")
      enter 'edit'
      debug_file 'edit'
    end
  end

  it 'must open an editor with specified file and line' do
    temporary_change_hash_value(ENV, 'EDITOR', 'editr') do
      Byebug::Edit.any_instance.expects(:system).
                                with("editr +3 #{fullpath('edit2')}")
      enter "edit #{fullpath('edit2')}:3"
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


  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      temporary_change_hash_value(ENV, 'EDITOR', 'editr') do
        Byebug::Edit.any_instance.expects(:system).
                                  with("editr +2 #{fullpath('edit')}")
        enter 'cont', "edit #{fullpath('edit')}:2", 'cont'
        debug_file 'post_mortem'
      end
    end
  end

end
