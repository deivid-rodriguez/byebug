# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Test settings display functionality.
  #
  class ShowTest < TestCase
    settings =
      %i[autolist autosave basename fullpath post_mortem stack_on_error]

    settings.each do |set|
      define_method(:"test_show_#{set}_shows_disabled_bool_setting_#{set}") do
        with_setting set, false do
          enter "show #{set}"
          debug_code(minimal_program)

          check_output_includes "#{set} is off"
        end
      end

      define_method(:"test_show_#{set}_shows_enabled_bool_setting_#{set}") do
        with_setting set, true do
          enter "show #{set}"
          debug_code(minimal_program)

          check_output_includes "#{set} is on"
        end
      end
    end

    def test_show_callstyle
      enter "show callstyle"
      debug_code(minimal_program)

      check_output_includes "Frame display callstyle is 'long'"
    end

    def test_show_listsize
      enter "show listsize"
      debug_code(minimal_program)

      check_output_includes "Number of source lines to list is 10"
    end

    def test_show_width
      width = Setting[:width]
      enter "show width"
      debug_code(minimal_program)

      check_output_includes "Maximum width of byebug's output is #{width}"
    end

    def test_show_unknown_setting
      enter "show bla"
      debug_code(minimal_program)

      check_error_includes "Unknown setting :bla"
    end

    def test_show_histfile
      filename = Setting[:histfile]
      enter "show histfile"
      debug_code(minimal_program)

      check_output_includes "The command history file is #{filename}"
    end

    def test_show_histsize
      max_size = Setting[:histsize]
      enter "show histsize"
      debug_code(minimal_program)

      check_output_includes \
        "Maximum size of byebug's command history is #{max_size}"
    end

    def test_show_without_arguments_displays_help_for_the_show_command
      enter "show"
      debug_code(minimal_program)

      check_output_includes("Shows byebug settings",
                            "List of supported settings:")
    end
  end
end
