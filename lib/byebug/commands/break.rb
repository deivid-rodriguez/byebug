module Byebug
  #
  # Implements breakpoint functionality
  #
  class BreakCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    POSITION_REGEXP = '(?:(\d+)|(.+?)[:.#]([^.:\s]+))'

    def regexp
      /^\s* b(?:reak)? (?:\s+ #{POSITION_REGEXP})? (?:\s+(.+))? \s*$/x
    end

    def execute
      return puts(self.class.help) if self.class.names.include?(@match[0])

      if @match[1]
        line, _, _, expr = @match.captures
      else
        _, file, line, expr = @match.captures
      end

      if expr && file.nil? && line.nil?
        return errmsg(pr('breakpoints.errors.location', expr: expr))
      elsif expr && expr !~ /^\s*if\s+(.+)/
        return errmsg(pr('breakpoints.errors.if', expr: expr))
      else
        expr = $1
      end

      if file.nil? && !@state.context
        return errmsg(pr('breakpoints.errors.state'))
      end

      file = @state.file if file.nil?
      line = @state.line.to_s if line.nil?

      if line =~ /^\d+$/
        path = File.expand_path(file)
        unless File.exist?(path)
          return errmsg(pr('breakpoints.errors.source', file: file))
        end

        file = CommandProcessor.canonic_file(path)
        l, n = line.to_i, File.foreach(path).count
        if l > n
          return errmsg(pr('breakpoints.errors.far_line', lines: n, file: file))
        end

        unless Breakpoint.potential_line?(path, l)
          return errmsg(pr('breakpoints.errors.line', line: l, file: file))
        end

        b = Breakpoint.add(path, l, expr)
        puts pr('breakpoints.set_breakpoint_to_line',
                id: b.id, file: file, line: l)

        unless syntax_valid?(expr)
          errmsg(pr('breakpoints.errors.expression', expr: expr))
          b.enabled = false
        end

      else
        kl = bb_warning_eval(file)
        unless kl && kl.is_a?(Module)
          return errmsg(pr('breakpoints.errors.class', file: file))
        end

        class_name, method = kl.name, line.intern
        b = Breakpoint.add(class_name, method, expr)
        puts pr('breakpoints.set_breakpoint_to_method',
                id: b.id, class: class_name, method: method)
      end
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
