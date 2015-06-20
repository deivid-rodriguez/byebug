require 'test_helper'
require 'byebug/runner'
require 'mocha/mini_test'

module Byebug
  class ScriptInterfaceTest < MiniTest::Test
    class InitializeTest < ScriptInterfaceTest
      def setup
        @file = mock
        File.expects(:open).with('file').returns(@file)
      end

      def test_initialize_wires_up_dependencies
        interface = ScriptInterface.new('file')
        assert_equal @file, interface.input
        assert interface.output.instance_of?(StringIO)
        assert interface.error.instance_of?(StringIO)
      end

      def test_initialize_verbose_writes_to_stdout_and_stderr
        interface = ScriptInterface.new('file', true)
        assert_equal @file, interface.input
        assert_equal STDOUT, interface.output
        assert_equal STDERR, interface.error
      end
    end

    class ReadlineTest < ScriptInterfaceTest
      class FakeFile
        def gets
        end
      end

      def setup
        @input = FakeFile.new
        File.expects(:open).with('file').returns(@input)

        @interface = ScriptInterface.new('file', true)
      end

      def test_readline_reads_input_until_first_non_comment
        @input.expects(:gets).times(3).returns('  #hello',
                                               '#hello',
                                               "test\n")

        output = sequence('output')
        @interface.output.expects(:puts).with('+   #hello').in_sequence(output)
        @interface.output.expects(:puts).with('+ #hello').in_sequence(output)
        @interface.output.expects(:puts).with("+ test\n").in_sequence(output)

        result = @interface.readline
        assert_equal 'test', result
      end
    end
  end
end
