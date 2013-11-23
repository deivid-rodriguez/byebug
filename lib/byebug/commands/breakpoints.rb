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

      brkpt_filename = file
      if file.nil?
        unless @state.context
          errmsg "We are not in a state that has an associated file.\n"
          return
        end
        brkpt_filename = @state.file
        if line.nil?
          # Set breakpoint at current line
          line = @state.line.to_s
        end
      elsif line !~ /^\d+$/
        # See if "line" is a method/function name
        klass = bb_warning_eval(file)
        if klass && klass.kind_of?(Module)
          class_name = klass.name if klass
        else
          errmsg "Unknown class #{file}.\n"
          throw :debug_error
        end
      end

      if line =~ /^\d+$/
        line = line.to_i
        if LineCache.cache(brkpt_filename, Command.settings[:autoreload])
          last_line = LineCache.size(brkpt_filename)
          return errmsg "There are only #{last_line} lines in file " \
                        "#{brkpt_filename}\n" if line > last_line

          return errmsg "Line #{line} is not a stopping point in file " \
                        "#{brkpt_filename}\n" unless
            LineCache.trace_line_numbers(brkpt_filename).member?(line)
        else
          errmsg "No source file named #{brkpt_filename}\n"
          return unless confirm("Set breakpoint anyway? (y/n) ")
        end

        b = Byebug.add_breakpoint brkpt_filename, line, expr
        print "Created breakpoint #{b.id} at " \
              "#{CommandProcessor.canonic_file(brkpt_filename)}:#{line.to_s}\n"
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
