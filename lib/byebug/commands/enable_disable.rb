module Byebug
  #
  # Mixin to assist command parsing
  #
  module EnableDisableFunctions
    def enable_disable_breakpoints(is_enable, args)
      return errmsg('No breakpoints have been set') if Breakpoint.none?

      all_breakpoints = Byebug.breakpoints.sort_by { |b| b.id }
      if args.empty?
        selected_breakpoints = all_breakpoints
      else
        selected_ids = []
        args.each do |pos|
          last_id = all_breakpoints.last.id
          pos, err = get_int(pos, "#{is_enable} breakpoints", 1, last_id)
          return errmsg(err) unless pos

          selected_ids << pos
        end
        selected_breakpoints = all_breakpoints.select do
          |b| selected_ids.include?(b.id)
        end
      end

      selected_breakpoints.each do |b|
        enabled = ('enable' == is_enable)
        if enabled && !syntax_valid?(b.expr)
          return errmsg("Expression \"#{b.expr}\" syntactically incorrect; " \
                        'breakpoint remains disabled.')
        end

        b.enabled = enabled
      end
    end

    def enable_disable_display(is_enable, args)
      if 0 == @state.display.size
        return errmsg('No display expressions have been set')
      end

      args.each do |pos|
        pos, err = get_int(pos, "#{is_enable} display", 1, @state.display.size)
        return errmsg(err) unless err.nil?

        @state.display[pos - 1][0] = ('enable' == is_enable)
      end
    end
  end

  #
  # Enabling or disabling custom display expressions or breakpoints.
  #
  class EnableDisableCommand < Command
    Subcommands = [
      ['breakpoints', 2, 'Enable/disable breakpoints. Give breakpoint '      \
                         'numbers (separated by spaces) as arguments or no ' \
                         'argument at all if you want to enable/disable '    \
                         'every breakpoint'],
      ['display', 2, 'Enable/disable some expressions to be displayed when ' \
                     ' when program stops. Arguments are the code numbers '  \
                     'of the expressions to resume/stop displaying. Do '     \
                     '"info display" to see the current list of code '       \
                     'numbers']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* (dis|en)(?:able)? (?:\s+(.+))? \s*$/x
    end

    def execute
      cmd = @match[1] == 'dis' ? 'disable' : 'enable'

      return errmsg("\"#{cmd}\" must be followed by \"display\", " \
                    "\"breakpoints\" or breakpoint ids") unless @match[2]

      args = @match[2].split(/[ \t]+/)
      param = args.shift
      subcmd = Command.find(Subcommands, param)
      if subcmd
        send("#{cmd}_#{subcmd.name}", args)
      else
        send("#{cmd}_breakpoints", args.unshift(param))
      end
    end

    def enable_breakpoints(args)
      enable_disable_breakpoints('enable', args)
    end

    def enable_display(args)
      enable_disable_display('enable', args)
    end

    def disable_breakpoints(args)
      enable_disable_breakpoints('disable', args)
    end

    def disable_display(args)
      enable_disable_display('disable', args)
    end

    class << self
      def names
        %w((en|dis)able)
      end

      def description
        %{(en|dis)[able][[ (breakpoints|display)][ n1[ n2[ ...[ nn]]]]]

         Enables or disables breakpoints or displays.

         "enable" by itself enables all breakpoints, just like
         "enable breakpoints". On the other side, "disable" or
         "disable breakpoints" disable all breakpoints.

         You can also specify a space separated list of breakpoint numbers to
         enable or disable specific breakpoints. You can use either
         "enable <id1> ... <idn>" or "enable breakpoints <id1> ... <idn>" and
         the same with "disable".

         If instead of "breakpoints" you specify "display", the command will
         work exactly the same way, but displays will get enabled/disabled
         instead of breakpoints.}
      end
    end
  end
end
