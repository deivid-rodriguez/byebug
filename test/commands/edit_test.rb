require 'mocha/mini_test'
require 'test_helper'

module Byebug
  #
  # Tests file editing from within Byebug.
  #
  class EditTestCase < TestCase
    def setup
      super

      @previous_editor = ENV['EDITOR']
    end

    def teardown
      ENV['EDITOR'] = @previous_editor

      super
    end

    def test_edit_opens_current_file_in_current_line_in_configured_editor
      ENV['EDITOR'] = 'edi'

      EditCommand.any_instance.expects(:system).with("edi +4 #{example_path}")

      enter 'edit'
      debug_code(minimal_program)
    end

    def test_edit_calls_vim_if_no_editor_environment_variable_is_set
      ENV['EDITOR'] = nil

      EditCommand.any_instance.expects(:system).with("vim +4 #{example_path}")

      enter 'edit'
      debug_code(minimal_program)
    end

    def test_edit_opens_configured_editor_at_specific_line_and_file
      ENV['EDITOR'] = 'edi'
      file = File.expand_path('README.md')

      EditCommand.any_instance.expects(:system).with("edi +3 #{file}")

      enter 'edit README.md:3'
      debug_code(minimal_program)
    end

    def test_edit_shows_an_error_if_specified_file_does_not_exist
      file = File.expand_path('no_such_file')
      enter 'edit no_such_file:6'
      debug_code(minimal_program)

      check_error_includes "File #{file} does not exist."
    end

    def test_edit_shows_an_error_if_the_specified_file_is_not_readable
      file = File.expand_path('README.md')
      File.stubs(:readable?).returns(false)
      enter 'edit README.md:6'
      debug_code(minimal_program)

      check_error_includes "File #{file} is not readable."
    end

    def test_edit_accepts_no_line_specification
      ENV['EDITOR'] = 'edi'
      file = File.expand_path('README.md')

      EditCommand.any_instance.expects(:system).with("edi #{file}")

      enter 'edit README.md'
      debug_code(minimal_program)
    end
  end
end
