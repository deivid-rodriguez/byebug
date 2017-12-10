require 'test_helper'

module Byebug
  #
  # Tests script processor in isolation
  #
  class ScriptProcessorTest < Minitest::Test
    include TestUtils

    def test_script_processor_clears_history
      with_init_file('set callstyle long') do
        interface = ScriptInterface.new(Byebug.init_file)

        previous_history = Readline::HISTORY.to_a

        ScriptProcessor.new(nil, interface).process_commands

        assert_equal previous_history, Readline::HISTORY.to_a
      end
    end
  end
end
