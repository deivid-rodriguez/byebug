module Byebug
  #
  # Implements breakpoint functionality
  #
  class BreakCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    POSITION_REGEXP = '(?:(\d+)|(.+?)[:.#]([^.:\s]+))'

    def regexp
      /^\s* b(?:reak)? (?:\s+ #{POSITION_REGEXP})? (?:\s+ if \s+(.+))? \s*$/x
    end

    def execute
      return puts(self.class.help) if self.class.names.include?(@match[0])

      if @match[1]
        file, line, expr = @state.file, @match[1], @match[4]
      else
        file, line, expr = @match[2..4]
      end

      return errmsg(pr('break.errors.no_breakpoint')) if line.nil? && expr
      return errmsg(pr('break.errors.location')) unless line
      return errmsg(pr('break.errors.state')) unless file

      breakpoint = if line =~ /^\d+$/
                     line_breakpoint(file, line, expr)
                   else
                     method_breakpoint(file, line, expr)
                   end

      return if syntax_valid?(expr)

      errmsg(pr('break.errors.expression', expr: expr))
      breakpoint.enabled = false
    end

    def line_breakpoint(file, line, expr)
      path = File.expand_path(file)
      unless File.exist?(path)
        return errmsg(pr('break.errors.source', file: file))
      end

      f = CommandProcessor.canonic_file(path)
      l, n = line.to_i, File.foreach(path).count
      if l > n
        return errmsg(pr('break.errors.far_line', lines: n, file: f))
      end

      unless Breakpoint.potential_line?(path, l)
        return errmsg(pr('break.errors.line', line: l, file: f))
      end

      b = Breakpoint.add(path, l, expr)
      puts pr('break.created_line', id: b.id, file: f, line: l)
      b
    end

    def method_breakpoint(klass, method, expr)
      k = bb_warning_eval(klass)
      if k && k.is_a?(Module)
        k = k.name
      else
        return errmsg(pr('break.errors.class', klass: klass))
      end

      m = method.intern
      b = Breakpoint.add(k, m, expr)
      puts pr('break.created_method', id: b.id, class: k, method: m)
      b
    end

    class << self
      def names
        %w(break)
      end

      def description
        <<-EOD.gsub(/^ {8}/, '')
          b[reak] file:line [if expr]
          b[reak] class(.|#)method [if expr]

          Set breakpoint to some position, (optionally) if expr == true
        EOD
      end
    end
  end
end
