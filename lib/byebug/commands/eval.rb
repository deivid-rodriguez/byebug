require 'byebug/command'

require 'English'
require 'pp'

module Byebug
  #
  # Utilities used by the eval command
  #
  module EvalFunctions
    #
    # Run block temporarily ignoring all TracePoint events.
    #
    # Used to evaluate stuff within Byebug's prompt. Otherwise, any code
    # creating new threads won't be properly evaluated because new threads will
    # get blocked by byebug's main thread.
    #
    def allowing_other_threads
      Byebug.unlock
      res = yield
      Byebug.lock
      res
    end

    #
    # Get current binding and yield it to the given block
    #
    def run_with_binding
      binding = get_binding
      yield binding
    end

    #
    # Evaluate +expression+ using +binding+
    #
    # @param binding [Binding] Context where to evaluate the expression
    # @param expression [String] Expression to evaluation
    # @param stack_on_error [Boolean] Whether to show a stack trace on error.
    #
    def eval_with_setting(binding, expression, stack_on_error)
      allowing_other_threads do
        if stack_on_error
          bb_eval(expression, binding)
        else
          bb_warning_eval(expression, binding)
        end
      end
    end
  end

  #
  # Evaluation of expressions from byebug's prompt.
  #
  class EvalCommand < Command
    include EvalFunctions

    self.allow_in_control = true

    def match(input)
      @input = input
      super
    end

    def regexp
      /^\s* e(?:val)? \s+/x
    end

    def execute
      expr = @match ? @match.post_match : @input
      run_with_binding do |b|
        res = eval_with_setting(b, expr, Setting[:stack_on_error])

        print pr('eval.result', expr: expr, result: res.inspect)
      end
    rescue
      puts "#{$ERROR_INFO.class} Exception: #{$ERROR_INFO.message}"
    end

    class << self
      def names
        %w(eval)
      end

      def description
        prettify <<-EOD
          e[val] <expression>

          Evaluates <expression> and prints its value.

          * NOTE - unknown input is automatically evaluated, to turn this off
          use 'set noautoeval'.
        EOD
      end
    end
  end

  #
  # Evaluation and pretty printing from byebug's prompt.
  #
  class PPCommand < Command
    include EvalFunctions

    self.allow_in_control = true

    def regexp
      /^\s* pp \s+/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        if Setting[:stack_on_error]
          PP.pp(bb_eval(@match.post_match, b), out)
        else
          PP.pp(bb_warning_eval(@match.post_match, b), out)
        end
      end
      puts out.string
    rescue
      out.puts $ERROR_INFO.message
    end

    class << self
      def names
        %w(pp)
      end

      def description
        prettify <<-EOD
          pp <expression>

          Evaluates <expression> and pretty-prints its value.
        EOD
      end
    end
  end

  #
  # Evaluation, pretty printing and columnizing from byebug's prompt.
  #
  class PutLCommand < Command
    include EvalFunctions
    include Columnize

    self.allow_in_control = true

    def regexp
      /^\s* putl \s+/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        res = eval_with_setting(b, @match.post_match, Setting[:stack_on_error])

        if res.is_a?(Array)
          puts "#{columnize(res.map(&:to_s), Setting[:width])}"
        else
          PP.pp(res, out)
          puts out.string
        end
      end
    rescue
      out.puts $ERROR_INFO.message
    end

    class << self
      def names
        %w(putl)
      end

      def description
        prettify <<-EOD
          putl <expression>

          Evaluates <expression>, an array, and columnize its value.
        EOD
      end
    end
  end

  #
  # Evaluation, pretty printing, columnizing and sorting from byebug's prompt
  #
  class PSCommand < Command
    include EvalFunctions
    include Columnize

    self.allow_in_control = true

    def regexp
      /^\s* ps \s+/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        res = eval_with_setting(b, @match.post_match, Setting[:stack_on_error])

        if res.is_a?(Array)
          puts "#{columnize(res.map(&:to_s).sort!, Setting[:width])}"
        else
          PP.pp(res, out)
          puts out.string
        end
      end
    rescue
      out.puts $ERROR_INFO.message
    end

    class << self
      def names
        %w(ps)
      end

      def description
        prettify <<-EOD
          ps <expression>

          Evaluates <expression>, an array, sort and columnize its value.
        EOD
      end
    end
  end
end
