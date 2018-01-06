# frozen_string_literal: true

SimpleCov.command_name ENV['MINITEST_TEST'] || 'MiniTest'
SimpleCov.add_filter '.bundle'
SimpleCov.start
