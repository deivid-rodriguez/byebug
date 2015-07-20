require 'English'
require 'pp'
require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Enhanced evaluation of expressions from byebug's prompt. Besides
  # evaluating, it sorts and pretty prints arrays.
  #
  class PsCommand < Command
    include Helpers::EvalHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* ps (\s+ (.+)) \s*$/x
    end

    def self.description
      <<-EOD
        ps <expression>

        #{short_description}
      EOD
    end

    def self.short_description
      'Evaluates an expression and prettyprints & sort the result'
    end

    def execute
      return puts(help) unless @match[1]

      res = thread_safe_eval(@match[1])
      res = res.sort if res.respond_to?(:sort)

      out = PP.pp(res, StringIO.new, Setting[:width])
      print pr('eval.result', expr: @match[1], result: out.string)
    end
  end
end
