module Byebug
  class EditTestCase < TestCase
    def setup
      @example = lambda do
        byebug
        Object.new
      end

      super
    end

    def teardown
      ENV['EDITOR'] = @previous_editor
    end

    def test_edit_opens_current_file_in_current_line_in_configured_editor
      ENV['EDITOR'] = 'edi'
      file = __FILE__
      EditCommand.any_instance.expects(:system).with("edi +6 #{file}")
      enter 'edit'
      debug_proc(@example)
    end

    def test_edit_calls_vim_if_no_editor_environment_variable_is_set
      ENV['EDITOR'] = nil
      file = __FILE__
      EditCommand.any_instance.expects(:system).with("vim +6 #{file}")
      enter 'edit'
      debug_proc(@example)
    end

    def test_edit_opens_configured_editor_at_specific_line_and_file
      ENV['EDITOR'] = 'edi'
      file = File.expand_path('README.md')
      EditCommand.any_instance.expects(:system).with("edi +3 #{file}")
      enter 'edit README.md:3'
      debug_proc(@example)
    end

    def test_edit_shows_an_error_if_specified_file_does_not_exist
      file = File.expand_path('no_such_file')
      enter 'edit no_such_file:6'
      debug_proc(@example)
      check_error_includes "File #{file} does not exist."
    end

    def test_edit_shows_an_error_if_the_specified_file_is_not_readable
      skip('for now')
    end

    def test_edit_accepts_no_line_specification
      ENV['EDITOR'] = 'edi'
      file = File.expand_path('README.md')
      EditCommand.any_instance.expects(:system).with("edi #{file}")
      enter 'edit README.md'
      debug_proc(@example)
    end
  end
end
