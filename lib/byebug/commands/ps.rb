require 'English'
require 'pp'
require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Evaluation, pretty printing, columnizing and sorting from byebug's prompt
  #
  class PsCommand < Command
    include Helpers::EvalHelper
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

    def description
      <<-EOD
        ps <expression>

        Evaluates <expression>, an array, sort and columnize its value.
      EOD
    end
  end
end
