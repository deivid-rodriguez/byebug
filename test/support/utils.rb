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
      Byebug.stubs(:run_init_script)
      interface.test_block = block
      begin
        program.call
      ensure
        interface.test_block.call if interface.test_block
      end
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
  end
end
