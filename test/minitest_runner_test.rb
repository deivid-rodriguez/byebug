# frozen_string_literal: true

require "test_helper"

module Byebug
  class MinitestRunnerTest < TestCase
    def test_runs
      output = run_minitest_runner("test/debugger_alias_test.rb")

      assert_includes output, "\n.\n"
    end

    def test_per_test_class
      output = run_minitest_runner("DebuggerAliasTest")

      assert_includes output, "\n.\n"
    end

    def test_per_test
      output = run_minitest_runner("test_aliases_debugger_to_byebug")

      assert_includes output, "\n.\n"
    end

    def test_combinations
      output = run_minitest_runner(
        "DebuggerAliasTest",
        "test_script_processor_clears_history"
      )

      assert_includes output, "\n..\n"
    end

    def test_with_verbose_option
      output = run_minitest_runner("DebuggerAliasTest", "--verbose")

      assert_includes \
        output,
        "Byebug::DebuggerAliasTest#test_aliases_debugger_to_byebug = 0.00 s = ."

      assert_includes \
        output,
        "Run options: --name=/DebuggerAliasTest/ --verbose"
    end

    def test_with_seed_option
      output = run_minitest_runner("DebuggerAliasTest", "--seed=37")

      assert_includes output, "\n.\n"

      assert_includes \
        output,
        "Run options: --name=/DebuggerAliasTest/ --seed=37"
    end

    private

    def run_minitest_runner(*args)
      Bundler.with_original_env do
        output, status = Open3.capture2e(shell_out_env(simplecov: false), *binstub, *args)

        assert_equal true, status.success?, output

        output
      end
    end

    def binstub
      cmd = "bin/minitest"
      return [cmd] unless Gem.win_platform?

      %W[#{RbConfig.ruby} #{cmd}]
    end
  end
end
