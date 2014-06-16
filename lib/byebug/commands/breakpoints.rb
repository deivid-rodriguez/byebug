module Byebug

  # Implements byebug "break" command.
  class BreakCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    def regexp
      /^\s* b(?:reak)? (?:\s+#{Position_regexp})? (?:\s+(.+))? \s*$/x
    end

    def execute
      return print BreakCommand.help(nil) if BreakCommand.names.include?(@match[0])

      if @match[1]
        line, _, _, expr = @match.captures
      else
        _, file, line, expr = @match.captures
      end
      if expr
        if expr !~ /^\s*if\s+(.+)/
          if file or line
            errmsg "Expecting \"if\" in breakpoint condition; got: #{expr}.\n"
          else
            errmsg "Invalid breakpoint location: #{expr}.\n"
          end
          return
        else
          expr = $1
        end
      end

      brkpt_file = file
      if file.nil?
        unless @state.context
          return errmsg "We are not in a state that has an associated file.\n"
        end
        brkpt_file = @state.file
        line = @state.line.to_s if line.nil?
      elsif line !~ /^\d+$/
        # See if "line" is a method/function name
        klass = bb_warning_eval(file)
        if klass && klass.kind_of?(Module)
          class_name = klass.name if klass
        else
          return errmsg "Unknown class #{file}.\n"
        end
      end

      if line =~ /^\d+$/
        line = line.to_i
        if LineCache.cache(brkpt_file, Setting[:autoreload])
          n = File.foreach(brkpt_file).count
          if line > n
            return errmsg "There are only #{n} lines in file #{brkpt_file}\n"
          end
          if !LineCache.trace_line_numbers(brkpt_file).member?(line)
            return errmsg "Line #{line} is not a valid stopping point in file\n"
          end
        else
          errmsg "No source file named #{brkpt_file}\n"
          return unless confirm("Set breakpoint anyway? (y/n) ")
        end

        b = Byebug.add_breakpoint brkpt_file, line, expr
        print "Created breakpoint #{b.id} at " \
              "#{CommandProcessor.canonic_file(brkpt_file)}:#{line.to_s}\n"
        unless syntax_valid?(expr)
          errmsg "Expression \"#{expr}\" syntactically incorrect; breakpoint" \
                 " disabled.\n"
          b.enabled = false
        end
      else
        method = line.intern
        b = Byebug.add_breakpoint class_name, method, expr
        print "Created breakpoint #{b.id} at #{class_name}::#{method.to_s}\n"
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

  # Implements byebug "delete" command.
  class DeleteCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    def regexp
      /^\s* del(?:ete)? (?:\s+(.*))?$/x
    end

    def execute
      return errmsg "We are not in a state we can delete breakpoints.\n" unless
        @state.context

      if not @match[1]
        Byebug.breakpoints.clear if confirm("Delete all breakpoints? (y or n) ")
      else
        @match[1].split(/[ \t]+/).each do |pos|
          return unless pos = get_int(pos, "Delete", 1)
          errmsg "No breakpoint number %d\n", pos unless
            Byebug.remove_breakpoint(pos)
        end
      end
    end

    class << self
      def names
        %w(delete)
      end

      def description
        %{del[ete][ nnn...]

          Without and argument, deletes all breakpoints. With integer arguments,
          it deletes specific breakpoints.}
      end
    end
  end

end
