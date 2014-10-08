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
    # Usage:
    #   enter 'b 12'
    #   enter 'b 12', 'cont'
    #   enter ['b 12', 'cont']
    #   enter 'b 12', ->{"disable #{breakpoint.id}"}, 'cont'
    #
    def enter(*messages)
      messages = messages.first.is_a?(Array) ? messages.first : messages
      interface.input.concat(messages)
    end

    #
    # Runs the provided Proc
    #
    # You also can specify a block, which will be executed when Processor
    # extracts all the commands from the input queue. You can use that for
    # making assertions on the current test. If you specified the block and it
    # was never executed, the test will fail.
    #
    # Usage:
    #   debug_proc -> { byebug; puts 'Hello' }
    #
    #   enter 'b 4', 'cont'
    #   code = -> do
    #     byebug
    #     puts 'hello'
    #   end
    #   debug_proc(code) { assert_equal 4, state.line }
    #
    def debug_proc(program, &block)
      interface.test_block = block
      program.call
    ensure
      interface.test_block.call if interface.test_block
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
    # namespace. The name of this class is defined by the `example_class'
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
    #     puts 'byebye'
    #   EOC
    #
    #   debug_code(prog) { assert_equal 3, state.line }
    #
    def debug_code(program, &block)
      interface.test_block = block
      File.open(example_path, 'w') { |file| file.write(program) }
      load(example_path)
    ensure
      Byebug.send(:remove_const, example_class)
      File.delete(example_path)
      interface.test_block.call if interface.test_block
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
    #     2:
    #     3:  puts 'bye'
    #   EOF
    #
    #   returns
    #
    #   <<-EOF
    #   puts 'hello'
    #
    #   puts 'bye'
    #   EOF
    #
    def strip_line_numbers(str_with_ruby_code)
      str_with_ruby_code.gsub(/  *\d+: ? ?/, '')
    end

    #
    # Set default settings for testing
    #
    def set_defaults
      Byebug::Setting.load

      Byebug::Setting[:autolist] = false
      Byebug::Setting[:autosave] = false
      Byebug::Setting[:testing] = true
      Byebug::Setting[:width] = 80
    end

    def interface
      Byebug.handler.interface
    end

    def state
      Thread.current.thread_variable_get('state')
    end

    def context
      state.context
    end

    def force_set_const(klass, const, value)
      klass.send(:remove_const, const) if klass.const_defined?(const)
      klass.const_set(const, value)
    end

    #
    # Modifies a line number in a file with new content.
    #
    # @param file File to be changed
    # @param line Line number to be changed
    # @param new_line_content New line content
    #
    def change_line(file, line, new_line_content)
      old_content = File.read(file)
      new_content = old_content.split("\n")
                               .tap { |c| c[line - 1] = new_line_content }
                               .join("\n") + "\n"
      File.open(file, 'w') { |f| f.write(new_content) }
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
  end
end
