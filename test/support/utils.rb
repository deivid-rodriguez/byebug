require_relative 'matchers'
require_relative 'test_interface'

module Byebug::TestUtils
  #
  # Adds commands to the input queue, so they will be later retrieved by
  # Processor, i.e., it emulates user's input.
  #
  # If a command is a Proc object, it will be executed before being retrieved by
  # Processor. May be handy when you need build a command depending on the
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
  # You also can specify a block, which will be executed when Processor extracts
  # all the commands from the input queue. You can use that for making asserts
  # on the current test. If you specified the block and it never was executed,
  # the test will fail.
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
  def check_output(check_method, *args)
    queue = args.last.is_a?(String) || args.last.is_a?(Regexp) ?
            interface.output_queue : args.pop
    queue_messages = queue.map(&:strip)
    messages = Array(args).map { |msg| msg.is_a?(String) ? msg.strip : msg }
    send(check_method, messages, queue_messages)
  end

  def check_error_includes(*args)
    check_output :assert_includes_in_order, *args, interface.error_queue
  end

  def check_output_includes(*args)
    check_output :assert_includes_in_order, *args
  end

  def check_output_doesnt_include(*args)
    check_output :refute_includes_in_order, *args
  end

  def interface
    Byebug.handler.interface
  end

  def state
    Thread.current.thread_variable_get('state')
  end

  def first_brkpt
    Byebug.breakpoints.first
  end

  def last_brkpt
    Byebug.breakpoints.last
  end

  def context
    state.context
  end

  def force_set_const(klass, const, value)
    force_unset_const(klass, const)
    klass.const_set(const, value)
  end

  def force_unset_const(klass, const)
    klass.send(:remove_const, const) if klass.const_defined?(const)
  end

  def change_line_in_file(file, line, new_line_content)
    old_content = File.read(file)
    new_content = old_content.split("\n")
                             .tap { |c| c[line - 1] = new_line_content }
                             .join("\n") + "\n"
    File.open(file, 'w') { |f| f.write(new_content) }
  end
end
