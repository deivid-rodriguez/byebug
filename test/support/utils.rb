require_relative 'matchers'
require_relative 'test_interface'

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
      interface.input_queue.concat(messages)
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
    # Checks the output of byebug.
    #
    # By default it checks output queue of the current interface, but you can
    # check again any queue by providing it as a second argument.
    #
    # Usage:
    #   enter 'break 4', 'cont'
    #   debug 'ex1'
    #   check_output "Breakpoint 1 at #{fullpath('ex1')}:4"
    #
    def check_output(check_method, queue, *args)
      queue_messages = queue.map(&:strip)
      messages = Array(args).map { |msg| msg.is_a?(String) ? msg.strip : msg }
      send(check_method, messages, queue_messages)
    end

    %w(output error confirm).each do |queue_name|
      define_method(:"check_#{queue_name}_includes") do |*args|
        queue = interface.send(:"#{queue_name}_queue")
        send(:check_output, :assert_includes_in_order, queue, *args)
      end

      define_method(:"check_#{queue_name}_doesnt_include") do |*args|
        queue = interface.send(:"#{queue_name}_queue")
        send(:check_output, :refute_includes_in_order, queue, *args)
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

    def change_line_in_file(file, line, new_line_content)
      old_content = File.read(file)
      new_content = old_content.split("\n")
                               .tap { |c| c[line - 1] = new_line_content }
                               .join("\n") + "\n"
      File.open(file, 'w') { |f| f.write(new_content) }
    end
  end
end
