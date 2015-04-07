require 'English'
require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Evaluation of expressions from byebug's prompt.
  #
  class EvalCommand < Command
    include Helpers::EvalHelper

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

    def description
      <<-EOD
        e[val] <expression>

        Evaluates <expression> and prints its value.

        * NOTE - unknown input is automatically evaluated, to turn this off use
        'set noautoeval'.
      EOD
    end
  end
end
