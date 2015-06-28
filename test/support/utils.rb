require_relative 'matchers'

module Byebug
  #
  # Misc tools for the test suite
  #
  module TestUtils
    #
    # Adds commands to the input queue, so they will be later retrieved by
    # Processor, i.e., it emulates user's input.
    #
    # If a command is a Proc object, it will be executed before being retrieved
    # by Processor. May be handy when you need build a command depending on the
    # current context/state.
    #
    # @example
    #
    #   enter 'b 12', 'cont'
    #   enter 'b 12', ->{ "disable #{breakpoint.id}" }, 'cont'
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
    #   enter 'next'
    #   prog <<-EOC
    #     byebug
    #     puts 'hello'
    #   EOC
    #
    #   debug_code(prog) { assert_equal 2, state.line }
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
    # Checks the confirm/output/error streams.
    #
    # Usage:
    #   enter 'break 4', 'cont'
    #   debug 'ex1'
    #   check_output "Breakpoint 1 at #{fullpath('ex1')}:4"
    #
    def check_stream(check_method, stream, *args)
      stream_messages = stream.map(&:strip)
      messages = Array(args).map { |msg| msg.is_a?(String) ? msg.strip : msg }
      send(check_method, messages, stream_messages)
    end

    %w(output error).each do |stream_name|
      define_method(:"check_#{stream_name}_includes") do |*args|
        stream = interface.send(stream_name)
        send(:check_stream, :assert_includes_in_order, stream, *args)
      end

      define_method(:"check_#{stream_name}_doesnt_include") do |*args|
        stream = interface.send(stream_name)
        send(:check_stream, :refute_includes_in_order, stream, *args)
      end
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
    #     1:  puts 'hello'
    #     2:  puts 'bye'
    #   EOF
    #
    #   returns
    #
    #   puts 'hello'
    #   puts 'bye'
    #
    def strip_line_numbers(str_with_ruby_code)
      str_with_ruby_code.gsub(/  *\d+: ? ?/, '')
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
    #   ['Sample command', 'It does an amazing thing.']
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
      splitted = split_lines(output_str)

      splitted.each { |str| Regexp.new(Regexp.escape(str), Regexp::EXTENDED) }
    end

    #
    # Shortcut to Byebug's global state
    #
    def state
      Byebug.handler.state
    end

    #
    # Shortcut to Byebug's interface
    #
    def interface
      Byebug.handler.interface
    end

    #
    # Shortcut to Byebug's context
    #
    def context
      state.context
    end

    #
    # Removes all (both enabled and disabled) displays
    #
    def clear_displays
      loop do
        break unless state.display.size > 0
        state.display.pop
      end
    end

    def force_set_const(klass, const, value)
      force_remove_const(klass, const)
      klass.const_set(const, value)
    end

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

      File.open(file, 'w') { |f| f.write(lines.join) }
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
    # Yields a block using temporary values for command line program name and
    # command line arguments.
    #
    # @param program_name [String] New value for the program name
    # @param *args [Array] New value for the program arguments
    #
    def with_command_line(program_name, *args)
      original_program_name = $PROGRAM_NAME
      original_argv = $ARGV
      $PROGRAM_NAME = program_name
      $ARGV.replace(args)

      yield
    ensure
      $PROGRAM_NAME = original_program_name
      $ARGV.replace(original_argv)
    end

    #
    # Yields a block using a temporary value for a setting
    #
    # @param key [Symbol] Setting key
    # @param value [Object] Temporary value for the setting
    #
    def with_setting(key, value)
      original_value = Setting[key]
      Setting[key] = value

      yield
    ensure
      Setting[key] = original_value
    end

    #
    # A minimal program that gives you a byebug's prompt
    #
    def minimal_program
      <<-EOM
        module Byebug
          byebug

          puts 'Hello world'
        end
      EOM
    end
  end
end
