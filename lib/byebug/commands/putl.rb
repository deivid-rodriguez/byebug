require 'pp'
require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Evaluation, pretty printing and columnizing from byebug's prompt.
  #
  class PutlCommand < Command
    include Helpers::EvalHelper
    include Columnize

    self.allow_in_control = true

    def regexp
      /^\s* putl (?:\s+ (.+))? \s*$/x
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        res = eval_with_setting(b, @match[1], Setting[:stack_on_error])

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

    def description
      <<-EOD
        putl <expression>

        Evaluates <expression>, an array, and columnize its value.
      EOD
    end
  end
end
