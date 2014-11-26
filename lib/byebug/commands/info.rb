module Byebug
  #
  # Utility methods to assist the info command
  #
  module InfoFunctions
    def info_catch(*_args)
      return puts('No frame selected.') unless @state.context

      if Byebug.catchpoints && !Byebug.catchpoints.empty?
        Byebug.catchpoints.each do |exception, _hits|
          puts("#{exception}: #{exception.is_a?(Class)}")
        end
      else
        puts 'No exceptions set to be caught.'
      end
    end

    def info_args(*args)
      locals = @state.context.frame_locals
      args = @state.context.frame_args
      return if args == [[:rest]]

      args.map do |_, name|
        s = "#{name} = #{locals[name].inspect}"
        s[Setting[:width] - 3..-1] = '...' if s.size > Setting[:width]
        puts s
      end
    end

    def info_breakpoint(brkpt)
      expr = brkpt.expr.nil? ? '' : " if #{brkpt.expr}"
      y_n = brkpt.enabled? ? 'y' : 'n'
      interp = format('%-3d %-3s at %s:%s%s',
                      brkpt.id, y_n, brkpt.source, brkpt.pos, expr)
      puts interp
      hits = brkpt.hit_count
      return unless hits > 0

      s = (hits > 1) ? 's' : ''
      puts "\tbreakpoint already hit #{hits} time#{s}"
    end

    def info_breakpoints(*args)
      return puts('No breakpoints.') if Byebug.breakpoints.empty?

      brkpts = Byebug.breakpoints.sort_by(&:id)
      unless args.empty?
        indices = args.map(&:to_i)
        brkpts = brkpts.select { |b| indices.member?(b.id) }
        return errmsg('No breakpoints found among list given') if brkpts.empty?
      end

      puts 'Num Enb What'
      brkpts.each { |b| info_breakpoint(b) }
    end

    def info_display(*_args)
      return puts('There are no auto-display expressions now.') unless
        @state.display.find { |d| d[0] }

      puts 'Auto-display expressions now in effect:'
      puts 'Num Enb Expression'
      n = 1
      @state.display.each do |d|
        puts(format('%3d: %s  %s', n, d[0] ? 'y' : 'n', d[1]))
        n += 1
      end
    end

    include FileFunctions

    def info_file_basic(file)
      path = File.expand_path(file)
      return unless File.exist?(path)

      puts "File #{path} (#{n_lines(path)} lines)"
    end

    def info_file_breakpoints(file)
      breakpoints = Breakpoint.potential_lines(file)
      return unless breakpoints

      puts "\tbreakpoint line numbers:"
      puts columnize(breakpoints.to_a.sort, Setting[:width])
    end

    def info_file_mtime(file)
      stat = File.stat(file)
      puts "\t#{stat.mtime}" if stat
    end

    def info_file_sha1(file)
      puts "\t#{Digest::SHA1.hexdigest(file)}"
    end

    def info_line(*_args)
      puts "Line #{@state.line} of \"#{@state.file}\""
    end

    def info_stop_reason(stop_reason)
      case stop_reason
      when :step
        puts "It stopped after stepping, next'ing or initial start."
      when :breakpoint
        puts 'It stopped at a breakpoint.'
      when :catchpoint
        puts 'It stopped at a catchpoint.'
      end
    end

    def info_program(*_args)
      if @state.context.dead?
        puts 'The program crashed.'
        excpt = Byebug.last_exception
        return puts("Exception: #{excpt.inspect}") if excpt
      end

      puts 'Program stopped. '
      info_stop_reason @state.context.stop_reason
    end
  end

  #
  # Show info about different aspects of the debugger.
  #
  class InfoCommand < Command
    include Columnize
    self.allow_in_control = true

    Subcommands = [
      ['args', 1, 'Argument variables of current stack frame'],
      ['breakpoints', 1, 'Status of user-settable breakpoints',
       'Without argument, list info about all breakpoints. With an integer ' \
       'argument, list info on that breakpoint.'],
      ['catch', 3, 'Exceptions that can be caught in the current stack frame'],
      ['display', 2, 'Expressions to display when program stops'],
      ['file', 4, 'Info about a particular file read in',
       'After the file name is supplied, you can list file attributes that ' \
       'you wish to see. Attributes are: "all", "breakpoint", "mtime" and ' \
       'A header show file path and number of lines is always displayed.'],
      ['line', 2, 'Line number and file name of current position in source ' \
                  'file.'],
      ['program', 2, 'Execution status of the program']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(Subcommands)

    InfoFileSubcommands = [
      ['all', 1, 'All information available - breakpoints, mtime and sha1'],
      ['breakpoints', 1, 'Show possible stopping points in the file'],
      ['mtime', 1, 'Show modification time of file'],
      ['sha1', 1, 'Show SHA1 hash of contents of the file']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(InfoFileSubcommands)

    def info_file(*args)
      file = args[0] || @state.file
      return "Don't know which file you want info about\n" unless file

      info_file_basic(file)
      return unless args[1]

      subcmd = Command.find(InfoFileSubcommands, args[1])
      return errmsg("Invalid parameter #{args[1]}\n") unless subcmd

      return send("info_file_#{subcmd.name}", file) unless subcmd.name == 'all'

      info_file_breakpoints(file)
      info_file_mtime(file)
      info_file_sha1(file)
    end

    def regexp
      /^\s* i(?:nfo)? (?:\s+(.+))? \s*$/x
    end

    def execute
      return puts(InfoCommand.help) unless @match[1]

      args = @match[1].split(/[ \t]+/)
      param = args.shift
      subcmd = Command.find(Subcommands, param)
      return errmsg "Unknown info command #{param}\n" unless subcmd

      if @state.context
        send("info_#{subcmd.name}", *args)
      else
        errmsg "info_#{subcmd.name} not available without a context.\n"
      end
    end

    class << self
      def names
        %w(info)
      end

      def description
        <<-EOD.gsub(/^ {8}/, '')

          info[ subcommand]

          Generic command for showing things about the program being debugged.

        EOD
      end

      def help(subcmds = [])
        return description + format_subcmds if subcmds.empty?

        subcmd = subcmds.first
        return format_subcmd(subcmd) unless 'file' == subcmd && subcmds[2]

        subsubcmd = Command.find(InfoFileSubcommands, subcmds[2])
        return "\nInvalid \"file\" attribute \"#{args[2]}\"." unless subsubcmd

        subsubcmd.short_help
      end
    end
  end
end
