require 'English'
require 'pp'

module Byebug
  #
  # Utilities used by the eval command
  #
  module EvalFunctions
    def run_with_binding
      binding = get_binding
      yield binding
    end
  end

  #
  # Evaluation of expressions from byebug's prompt.
  #
  class EvalCommand < Command
    self.allow_in_control = true

    def match(input)
      @input = input
      super
    end

    def regexp
      /^\s* (p|e(?:val)?)\s+/x
    end

    def execute
      expr = @match ? @match.post_match : @input
      run_with_binding do |b|
        if Setting[:stack_on_error]
          puts "#{bb_eval(expr, b).inspect}"
        else
          puts "#{bb_warning_eval(expr, b).inspect}"
        end
      end
    rescue
      puts "#{$ERROR_INFO.class} Exception: #{$ERROR_INFO.message}"
    end

    class << self
      def names
        %w(p eval)
      end

      def description
        %{(p|e[val]) <expression>

          Evaluates <expression> and prints its value.

          * NOTE - unknown input is automatically evaluated, to turn this off
          use 'set noautoeval'.}
      end
    end
  end

  #
  # Evaluation and pretty printing from byebug's prompt.
  #
  class PPCommand < Command
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
        %(pp <expression>

          Evaluates <expression> and pretty-prints its value.)
      end
    end
  end

  #
  # Evaluation, pretty printing and columnizing from byebug's prompt.
  #
  class PutLCommand < Command
    include Columnize
    self.allow_in_control = true

    def regexp
      /^\s* putl\s+/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        if Setting[:stack_on_error]
          vals = bb_eval(@match.post_match, b)
        else
          vals = bb_warning_eval(@match.post_match, b)
        end
        if vals.is_a?(Array)
          vals = vals.map { |item| item.to_s }
          puts "#{columnize(vals, Setting[:width])}"
        else
          PP.pp(vals, out)
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
        %(putl <expression>

          Evaluates <expression>, an array, and columnize its value.)
      end
    end
  end

  #
  # Evaluation, pretty printing, columnizing and sorting from byebug's prompt
  #
  class PSCommand < Command
    include Columnize
    self.allow_in_control = true

    def regexp
      /^\s* ps\s+/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        if Setting[:stack_on_error]
          vals = bb_eval(@match.post_match, b)
        else
          vals = bb_warning_eval(@match.post_match, b)
        end
        if vals.is_a?(Array)
          vals = vals.map { |item| item.to_s }
          puts "#{columnize(vals.sort!, Setting[:width])}"
        else
          PP.pp(vals, out)
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
        %(ps <expression>

          Evaluates <expression>, an array, sort and columnize its value.)
      end
    end
  end
end
