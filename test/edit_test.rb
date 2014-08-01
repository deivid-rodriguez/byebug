module Byebug
  class EditTestCase < TestCase
    def setup
      @example = -> do
        byebug
        Object.new
      end

      super
    end

    def after
      ENV['EDITOR'] = @previous_editor
    end

    def test_edit_opens_current_file_in_current_line_in_configured_editor
      ENV['EDITOR'] = 'edi'
      file = __FILE__
      EditCommand.any_instance.expects(:system).with("edi +6 #{file}")
      enter 'edit'
      debug_proc(@example)
    end

    def test_edit_calls_vim_if_no_EDITOR_environment_variable_is_set
      ENV['EDITOR'] = nil
      file = __FILE__
      EditCommand.any_instance.expects(:system).with("vim +6 #{file}")
      enter 'edit'
      debug_proc(@example)
    end

    def test_edit_opens_configured_editor_at_specific_line_and_file
      ENV['EDITOR'] = 'edi'
      file = File.expand_path('test/test_helper.rb')
      EditCommand.any_instance.expects(:system).with("edi +3 #{file}")
      enter "edit #{file}:3"
      debug_proc(@example)
    end

    def test_edit_shows_an_error_if_file_specified_does_not_exists
      enter "edit no_such_file:6"
      debug_proc(@example)
      check_error_includes 'File "no_such_file" is not readable.'
    end

    def test_edit_shows_an_error_if_incorrect_syntax_is_used
      enter 'edit blabla'
      debug_proc(@example)
      check_error_includes 'Invalid file[:line] number specification: blabla'
    end
  end
end
