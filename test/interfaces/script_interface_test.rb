require 'test_helper'

module Byebug
  #
  # Tests the script interface (batch execution of byebug commands from a file)
  #
  class ScriptInterfaceTest < TestCase
    def test_initialize_wires_up_dependencies
      with_new_tempfile('show') do |path|
        interface = ScriptInterface.new(path)

        assert_instance_of File, interface.input
        assert_instance_of File, interface.output
        assert_instance_of File, interface.error
      end
    end

    def test_initialize_verbose_writes_to_terminal
      with_new_tempfile('show') do |path|
        interface = ScriptInterface.new(path, true)

        assert_instance_of File, interface.input
        assert interface.output.tty?
        assert interface.error.tty?
      end
    end

    def test_readline_reads_input_until_first_non_comment
      with_new_tempfile("# Run the show command\nshow\n") do |path|
        interface = ScriptInterface.new(path)

        assert_equal 'show', interface.readline
      end
    end
  end
end
