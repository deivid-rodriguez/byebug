# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests file editing from within Byebug.
  #
  class EditTest < TestCase
    def test_edit_opens_current_file_in_current_line_in_configured_editor
      with_env("EDITOR", "edi") do
        assert_calls(Kernel, :system, "edi +4 #{example_path}") do
          enter "edit"
          debug_code(minimal_program)
        end
      end
    end

    def test_edit_calls_vim_if_no_editor_environment_variable_is_set
      with_env("EDITOR", nil) do
        assert_calls(Kernel, :system, "vim +4 #{example_path}") do
          enter "edit"
          debug_code(minimal_program)
        end
      end
    end

    def test_edit_opens_configured_editor_at_specific_line_and_file
      with_env("EDITOR", "edi") do
        assert_calls(Kernel, :system, "edi +3 #{readme_path}") do
          enter "edit README.md:3"
          debug_code(minimal_program)
        end
      end
    end

    def test_edit_shows_an_error_if_specified_file_does_not_exist
      file = File.expand_path("no_such_file")
      enter "edit no_such_file:6"
      debug_code(minimal_program)

      check_error_includes "File #{file} does not exist."
    end

    def test_edit_shows_an_error_if_the_specified_file_is_not_readable
      File.stub(:readable?, false) do
        enter "edit README.md:6"
        debug_code(minimal_program)

        check_error_includes "File #{readme_path} is not readable."
      end
    end

    def test_edit_accepts_no_line_specification
      with_env("EDITOR", "edi") do
        assert_calls(Kernel, :system, "edi #{readme_path}") do
          enter "edit README.md"
          debug_code(minimal_program)
        end
      end
    end

    private

    def readme_path
      File.expand_path("README.md")
    end
  end
end
