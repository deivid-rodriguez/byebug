require 'byebug/command'
require 'byebug/helpers/eval'
require 'byebug/helpers/file'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements breakpoint functionality
  #
  class BreakCommand < Command
    include Helpers::EvalHelper
    include Helpers::FileHelper
    include Helpers::ParseHelper

    self.allow_in_control = true

    def self.regexp
      /^\s* b(?:reak)? (?:\s+ (\S+))? (?:\s+ if \s+(.+))? \s*$/x
    end

    def self.description
      <<-EOD
        b[reak] [file:]line [if expr]
        b[reak] [module::...]class(.|#)method [if expr]

        They can be specified by line or method and an expression can be added
        for conditionally enabled breakpoints.

        #{short_description}
      EOD
    end

    def self.short_description
      'Sets breakpoints in the source code'
    end

    def execute
      return puts(help) unless @match[1]

      b = line_breakpoint(@match[1]) || method_breakpoint(@match[1])

      if syntax_valid?(@match[2])
        return puts(pr('break.created', id: b.id, file: b.source, line: b.pos))
      end

      errmsg(pr('break.errors.expression', expr: @match[2]))
      b.enabled = false
    end

    private

    def line_breakpoint(loc)
      line = loc.match(/^(\d+)$/)
      file_line = loc.match(/^([^:]+):(\d+)$/)
      return unless line || file_line

      f, l = line ? [frame.file, line[1]] : [file_line[1], file_line[2]]

      check_errors(f, l.to_i)

      Breakpoint.add(File.expand_path(f), l.to_i, @match[2])
    end

    def method_breakpoint(location)
      location.match(/([^.#]+)[.#](.+)/) do |match|
        klass = target_object(match[1])
        method = match[2].intern

        Breakpoint.add(klass, method, @match[2])
      end
    end

    def target_object(str)
      k = warning_eval(str)

      k && k.is_a?(Module) ? k.name : str
    rescue
      errmsg('Warning: breakpoint source is not yet defined')
      str
    end

    def check_errors(file, line)
      path = File.expand_path(file)
      deco_path = normalize(file)

      fail(pr('break.errors.source', file: deco_path)) unless File.exist?(path)

      if line > n_lines(file)
        fail(pr('break.errors.far_line', lines: n_lines(file), file: deco_path))
      end

      return if Breakpoint.potential_line?(path, line)

      fail(pr('break.errors.line', file: deco_path, line: line))
    end
  end
end
