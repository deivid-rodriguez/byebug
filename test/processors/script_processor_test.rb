# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests script processor in isolation
  #
  class ScriptProcessorTest < Minitest::Test
    include TestUtils

    def test_script_processor_clears_history
      previous_history = Reline::HISTORY.to_a

      process_rc_file("set callstyle long")

      assert_equal previous_history, Reline::HISTORY.to_a
    end

    def test_script_processor_closes_files
      process_rc_file("set callstyle long")

      assert_equal 0, dangling_descriptors.count
    end

    private

    def dangling_descriptors
      ObjectSpace.each_object(File).select do |f|
        f.path == Byebug.init_file && !f.closed?
      end
    end

    def process_rc_file(content)
      with_init_file(content) do
        interface = ScriptInterface.new(Byebug.init_file)

        ScriptProcessor.new(nil, interface).process_commands
      end
    end
  end
end
