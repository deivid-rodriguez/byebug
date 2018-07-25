# frozen_string_literal: true

require "support/matchers"
require "support/temporary"
require "open3"

module Byebug
  #
  # Misc tools for the test suite
  #
  module TestUtils
    include TestMatchers
    include TestTemporary

    #
    # Adds commands to the input queue, so they will be later retrieved by
    # Processor, i.e., it emulates user's input.
    #
    # If a command is a Proc object, it will be executed before being retrieved
    # by Processor. May be handy when you need build a command depending on the
    # current context.
    #
    # @example
    #
    #   enter "b 12", "cont"
    #   enter "b 12", ->{ "disable #{breakpoint.id}" }, "cont"
    #
    def enter(*messages)
      interface.input.concat(messages)
    end

    #
    # Runs the code block passed as a string.
    #
    # The string is copied to a new file and then that file is run. This is
    # done, instead of using `instance_eval` or similar techniques, because
    # it's useful to load a real file in order to make assertions on backtraces
    # or file names.
    #
    # @param program String containing Ruby code to be run. This string could
    # be any valid Ruby code, but in order to avoid redefinition warnings in
    # the test suite, it should define at most one class inside the Byebug
    # namespace. The name of this class is defined by the +example_class+
    # method.
    #
    # @param &block Optional proc which will be executed when Processor
    # extracts all the commands from the input queue. You can use that for
    # making assertions on the current test. If you specified the block and it
    # was never executed, the test will fail.
    #
    # @example
    #
    #   enter "next"
    #   prog <<-RUBY
    #     byebug
    #     puts "hello"
    #   RUBY
    #
    #   debug_code(prog) { assert_equal 3, frame.line }
    #
    def debug_code(program, &block)
      interface.test_block = block
      debug_in_temp_file(program)
      interface.test_block.call if interface.test_block
    end

    #
    # Writes a string containing Ruby code to a file and then debugs that file.
    #
    # @param program [String] Ruby code to be debugged
    #
    def debug_in_temp_file(program)
      example_file.write(program)
      example_file.close

      load(example_path)
    end

    #
    # Strips line numbers from a here doc containing ruby code.
    #
    # @param str_with_ruby_code A here doc containing lines of ruby code, each
    # one labeled with a line number
    #
    # @example
    #
    #   strip_line_numbers <<-EOF
    #     1:  puts "hello"
    #     2:  puts "bye"
    #   EOF
    #
    #   returns
    #
    #   puts "hello"
    #   puts "bye"
    #
    def strip_line_numbers(str_with_ruby_code)
      str_with_ruby_code.gsub(/  *\d+: ? ?/, "")
    end

    #
    # Split a string (normally a here doc containing byebug's output) into
    # stripped lines
    #
    # @param output_str [String]
    #
    # @example
    #
    #   split_lines <<-EOF
    #     Sample command
    #
    #     It does an amazing thing.
    #   EOF
    #
    #   returns
    #
    #   ["Sample command", "It does an amazing thing."]
    #
    def split_lines(output_str)
      output_str.split("\n").map(&:strip)
    end

    #
    # Prepares a string to get feed to an assertion accepting arrays of
    # Regexp's. The string is split into lines and each of them is converted to
    # a regexp, properly escaping it and ignoring whitespace.
    #
    # @param output_str [String]
    #
    def prepare_for_regexp(output_str)
      split_lines(output_str).map do |str|
        Regexp.new(Regexp.escape(str), Regexp::EXTENDED)
      end
    end

    #
    # Shortcut to Byebug's interface
    #
    def interface
      Context.interface
    end

    #
    # Shortcut to Byebug's context
    #
    def context
      Byebug.current_context
    end

    #
    # Shortcut to current frame
    #
    def frame
      context.frame
    end

    #
    # Removes all (both enabled and disabled) displays
    #
    def clear_displays
      loop do
        break if Byebug.displays.empty?

        Byebug.displays.pop
      end
    end

    #
    # Remove +const+ from +klass+ without a warning
    #
    def force_remove_const(klass, const)
      klass.send(:remove_const, const) if klass.const_defined?(const)
    end

    #
    # Modifies a line number in a file with new content.
    #
    # @param filename File to be changed
    # @param lineno Line number to be changed
    # @param new_line New line content
    #
    def change_line(file, lineno, new_line)
      lines = File.readlines(file).tap { |c| c[lineno - 1] = "#{new_line}\n" }

      File.open(file, "w") { |f| f.write(lines.join) }
    end

    #
    # Replaces line number <lineno> in file <file> with content <content>
    #
    # @param lineno Line number of line to be replaced.
    # @param file File containing the line to be replaced.
    # @param content New content for the line.
    # @param cmd Command to be run right after changing the line.
    #
    def cmd_after_replace(file, lineno, content, cmd)
      change_line(file, lineno, content)
      cmd
    end

    #
    # A minimal program that gives you a byebug's prompt
    #
    def minimal_program
      <<-RUBY
        module Byebug
          byebug

          "Hello world"
        end
      RUBY
    end

    #
    # Runs program <cmd> in a subprocess feeding it with some input <input> and
    # returns the output of the program.
    #
    # @param cmd [Array] Command line to be run.
    # @param input [String] Input string to feed to the program.
    #
    # @return Program's output
    #
    def run_program(cmd, input = "")
      stdout, = Open3.capture2e(shell_out_env, *cmd, stdin_data: input)

      stdout
    end

    #
    # Runs byebug in a subprocess feeding it with some input <input> and with
    # environment <env>.
    #
    # @param env [Hash] Environment to be passed to the subprocess.
    # @param *args [Array] Args to be passed to byebug.
    # @param input [String] Input string to feed to byebug.
    #
    # @return Byebug's output
    #
    def run_byebug(*args, input: "")
      run_program([*binstub, *args], input)
    end

    #
    # Common environment shared by specs that shell out. It needs to:
    #
    # * Adds byebug to the LOAD_PATH.
    # * (Optionally) Setup coverage tracking so that coverage in the subprocess
    #   is tracked.
    #
    def shell_out_env(simplecov: true)
      minitest_test = Thread.current.backtrace_locations.find do |location|
        location.label.start_with?("test_")
      end

      byebug_dir = File.absolute_path(File.join("..", "..", "lib"), __dir__)

      base = {
        "MINITEST_TEST" => "#{self.class}##{minitest_test.label}",
        "RUBYOPT" => "-I #{byebug_dir}"
      }

      base["RUBYOPT"] += " -r simplecov" if simplecov

      base
    end

    #
    # Binstub command used to run byebug in standalone mode during tests
    #
    def binstub
      cmd = "exe/byebug"
      return [cmd] unless Gem.win_platform?

      [RbConfig.ruby, cmd]
    end
  end
end
