require 'English'
require 'pp'
require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Evaluation and pretty printing from byebug's prompt.
  #
  class PpCommand < Command
    include Helpers::EvalHelper

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

    def description
      <<-EOD
        pp <expression>

        Evaluates <expression> and pretty-prints its value.
      EOD
    end
  end
end
