# frozen_string_literal: true

SimpleCov.start do
  coverage_dir ENV["CIRCLE_JOB"] ? "coverage/#{ENV['CIRCLE_JOB']}" : "coverage"
  command_name ENV["MINITEST_TEST"] || "MiniTest"
  add_filter ".bundle"
end
