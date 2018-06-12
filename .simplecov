# frozen_string_literal: true

SimpleCov.start do
  command_name ENV["MINITEST_TEST"] || "MiniTest"
  add_filter ".bundle"
end
