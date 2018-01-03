# frozen_string_literal: true

SimpleCov.command_name ENV['MINITEST_RUNNER_TEST'] || 'MiniTest'
SimpleCov.add_filter '.bundle'
SimpleCov.start
