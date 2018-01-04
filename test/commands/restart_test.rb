# frozen_string_literal: true

require "test_helper"
require "rbconfig"
require "byebug/helpers/string"

module Byebug
  #
  # Tests restarting functionality.
  #
  class RestartTest < TestCase
    include Helpers::StringHelper

    def setup
      super

      example_file.write(program)
      example_file.close
    end

    def program
      deindent <<-'RUBY', leading_spaces: 8
        #!/usr/bin/env ruby

        require "English"
        require "byebug"

        byebug

        if $ARGV.empty?
          print "Run program #{$PROGRAM_NAME} with no args"
        else
          print "Run program #{$PROGRAM_NAME} with args #{$ARGV.join(',')}"
        end
      RUBY
    end

    def test_restart_with_no_args__original_script_with_no_args__standalone
      skip if Gem.win_platform?

      output = run_program("#{byebug_bin} #{example_path}", "restart")

      assert_match(/Run program #{example_path} with no args/, output)
    end

    def test_restart_with_no_args__original_script_with_no_args__attached
      skip if Gem.win_platform?

      output = run_program(example_path, "restart")

      assert_match(/Run program #{example_path} with no args/, output)
    end

    def test_restart_with_no_args__original_script_through_ruby__attached
      output = run_program("#{ruby_bin} #{example_path}", "restart")

      assert_match(/Run program #{example_path} with no args/, output)
    end

    def test_restart_with_no_args__standalone
      skip if Gem.win_platform?

      output = run_program("#{byebug_bin} #{example_path} 1", "restart")

      assert_match(/Run program #{example_path} with args 1/, output)
    end

    def test_restart_with_args__standalone
      skip if Gem.win_platform?

      output = run_program("#{byebug_bin} #{example_path} 1", "restart 2")

      assert_match(/Run program #{example_path} with args 2/, output)
    end

    def test_restart_with_no_args__attached
      output = run_program("#{example_path} 1", "restart")

      assert_match(/Run program #{example_path} with args 1/, output)
    end

    def test_restart_with_args__attached
      output = run_program("#{example_path} 1", "restart 2")

      assert_match(/Run program #{example_path} with args 2/, output)
    end

    private

    def ruby_bin
      RbConfig.ruby
    end

    def byebug_bin
      Context.bin_file
    end
  end
end
