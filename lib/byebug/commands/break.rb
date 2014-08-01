module Byebug
  class BreakCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    def regexp
      /^\s* b(?:reak)? (?:\s+ #{Position_regexp})? (?:\s+(.+))? \s*$/x
    end

    def execute
      return print BreakCommand.help(nil) if BreakCommand.names.include?(@match[0])

      if @match[1]
        line, _, _, expr = @match.captures
      else
        _, file, line, expr = @match.captures
      end

      if expr && file.nil? && line.nil?
        return errmsg "Invalid breakpoint location: #{expr}\n"
      elsif expr && expr !~ /^\s*if\s+(.+)/
        return errmsg "Expecting \"if\" in breakpoint condition, got: #{expr}\n"
      else
        expr = $1
      end

      if file.nil? && !@state.context
        return errmsg "We are not in a state that has an associated file\n"
      end

      file = @state.file if file.nil?
      line = @state.line.to_s if line.nil?

      if line =~ /^\d+$/
        path = CommandProcessor.canonic_file(file)
        return errmsg "No file named #{path}\n" unless File.exist?(file)

        line, n = line.to_i, File.foreach(file).count
        return errmsg "There are only #{n} lines in file #{path}\n" if line > n

        autoreload = Setting[:autoreload]
        possible_lines = LineCache.trace_line_numbers(file, autoreload)
        if !possible_lines.member?(line)
          return errmsg \
            "Line #{line} is not a valid breakpoint in file #{path}\n"
        end

        b = Byebug.add_breakpoint file, line, expr
        print "Created breakpoint #{b.id} at #{path}:#{line}\n"

        if !syntax_valid?(expr)
          errmsg "Incorrect expression \"#{expr}\"; breakpoint disabled.\n"
          b.enabled = false
        end

      else
        klass = bb_warning_eval(file)
        if klass && klass.kind_of?(Module)
          class_name = klass.name
        else
          return errmsg "Unknown class #{file}\n"
        end

        method = line.intern
        b = Byebug.add_breakpoint class_name, method, expr
        print "Created breakpoint #{b.id} at #{class_name}::#{method}\n"
      end
    end

    class << self
      def names
        %w(break)
      end

      def description
        %{b[reak] file:line [if expr]
          b[reak] class(.|#)method [if expr]

          Set breakpoint to some position, (optionally) if expr == true}
      end
    end
  end
end
