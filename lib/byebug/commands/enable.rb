module Byebug

  # Mix-in module to assist in command parsing.
  module EnableDisableFunctions
    def enable_disable_breakpoints(is_enable, args)
      breakpoints = Byebug.breakpoints.sort_by{|b| b.id }
      largest = breakpoints.inject(0) do |tally, b|
        tally = b.id if b.id > tally
      end
      if 0 == largest
        errmsg "No breakpoints have been set.\n"
        return
      end
      args.each do |pos|
        pos = get_int(pos, "#{is_enable} breakpoints", 1, largest)
        return nil unless pos
        breakpoints.each do |b|
          if b.id == pos
            enabled = ('enable' == is_enable)
            if enabled
              unless syntax_valid?(b.expr)
                errmsg "Expression \"#{b.expr}\" syntactically incorrect; " \
                       "breakpoint remains disabled.\n"
                break
              end
            end
            b.enabled = ('enable' == is_enable)
            break
          end
        end
      end
    end

    def enable_disable_display(is_enable, args)
      if 0 == @state.display.size
        errmsg "No display expressions have been set.\n"
        return
      end
      args.each do |pos|
        pos = get_int(pos, "#{is_enable} display", 1, @state.display.size)
        return nil unless pos
        @state.display[pos-1][0] = ('enable' == is_enable)
      end
    end
  end

  class EnableCommand < Command
    Subcommands =
      [
       ['breakpoints', 2, 'Enable specified breakpoints',
        'Give breakpoint numbers (separated by spaces) as arguments. This is ' \
        'used to cancel the effect of the "disable" command.'],
       ['display', 2,
        'Enable some expressions to be displayed when program stops',
        'Arguments are the code numbers of the expressions to resume '   \
        'displaying. Do "info display" to see the current list of code ' \
        'numbers.'],
      ].map do |name, min, short_help, long_help|
        Subcmd.new(name, min, short_help, long_help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* en(?:able)? (?:\s+(.+))? \s*$/x
    end

    def execute
      return errmsg "\"enable\" must be followed by \"display\", " \
                    "\"breakpoints\" or breakpoint numbers.\n" unless @match[1]

      args = @match[1].split(/[ \t]+/)
      param = args.shift
      subcmd = Command.find(Subcommands, param)
      if subcmd
        send("enable_#{subcmd.name}", args)
      else
        send('enable_breakpoints', args.unshift(param))
      end
    end

    def enable_breakpoints(args)
      enable_disable_breakpoints('enable', args)
    end

    def enable_display(args)
      enable_disable_display('enable', args)
    end

    class << self
      def names
        %w(enable)
      end

      def description
        %{Enable breakpoints or displays.

          This is used to cancel the effect of the "disable" command.
         }
      end
    end
  end

  class DisableCommand < Command
    Subcommands =
      [
       ['breakpoints', 1, 'Disable some breakpoints',
        'Arguments are breakpoint numbers with spaces in between. A disabled ' \
        'breakpoint is not forgotten, but has no effect until reenabled.'],
       ['display', 1, 'Disable some display expressions when program stops',
        'Arguments are the code numbers of the expressions to stop '       \
        'displaying. Do "info display" to see the current list of code ' \
        'numbers.'],
      ].map do |name, min, short_help, long_help|
      Subcmd.new(name, min, short_help, long_help)
    end unless defined?(Subcommands)

    def regexp
      /^\s* dis(?:able)? (?:\s+(.+))? \s*$/x
    end

    def execute
      return errmsg "\"disable\" must be followed by \"display\", " \
                    "\"breakpoints\" or breakpoint numbers.\n" unless @match[1]

      args = @match[1].split(/[ \t]+/)
      param = args.shift
      subcmd = Command.find(Subcommands, param)
      if subcmd
        send("disable_#{subcmd.name}", args)
      else
        send('disable_breakpoints', args.unshift(param))
      end
    end

    def disable_breakpoints(args)
      enable_disable_breakpoints('disable', args)
    end

    def disable_display(args)
      enable_disable_display('disable', args)
    end

    class << self
      def names
        %w(disable)
      end

      def description
        %{Disable breakpoints or displays.

          A disabled item is not forgotten, but has no effect until reenabled.
          Use the "enable" command to have it take effect again.
         }
      end
    end
  end

end
