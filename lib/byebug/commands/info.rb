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

      brkpts = Byebug.breakpoints.sort_by { |b| b.id }
      unless args.empty?
        indices = args.map { |a| a.to_i }
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

    def info_file_path(file)
      s = "File #{file}"
      path = File.expand_path(file)
      s = "#{s} - #{path}" if path && path != file
      puts s
    end

    def info_file_lines(file)
      lines = File.foreach(file)
      puts "\t#{lines.count} lines" if lines
    end

    def info_file_breakpoints(file)
      breakpoints = LineCache.trace_line_numbers(file)
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

    def info_files(*_args)
      files = SCRIPT_LINES__.keys
      files.uniq.sort.each do |file|
        info_file_path(file)
        info_file_mtime(file)
      end
    end

    def info_line(*_args)
      puts "Line #{@state.line} of \"#{@state.file}\""
    end

    def print_hash(vars)
      vars.keys.sort.each do |name|
        begin
          s = "#{name} = #{vars[name].inspect}"
        rescue
          begin
            s = "#{name} = #{vars[name]}"
            rescue
              s = "#{name} = *Error in evaluation*"
          end
        end
        s[Setting[:width] - 3..-1] = '...' if s.size > Setting[:width]
        puts s
      end
    end

    def info_stop_reason(stop_reason)
      case stop_reason
      when :step
        puts "It stopped after stepping, next'ing or initial start."
      when :breakpoint
        puts 'It stopped at a breakpoint.'
      when :catchpoint
        puts 'It stopped at a catchpoint.'
      else
        puts "Unknown reason: #{@state.context.stop_reason}"
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

    def info_variables(*_args)
      locals = @state.context.frame_locals
      locals[:self] = @state.context.frame_self(@state.frame_pos)
      print_hash(locals)

      obj = bb_eval('self')
      var_list(obj.instance_variables, obj.instance_eval { binding })
      var_class_self
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
       'you wish to see. Attributes include: "all", "basic", "breakpoint", ' \
       '"lines", "mtime", "path" and "sha1".'],
      ['files', 5, 'File names and timestamps of files read in'],
      ['line', 2, 'Line number and file name of current position in source ' \
                  'file.'],
      ['program', 2, 'Execution status of the program']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(Subcommands)

    InfoFileSubcommands = [
      ['all', 1, 'All file information available - breakpoints, lines, '     \
                 'mtime, path and sha1'],
      ['basic', 2, 'basic information - path, number of lines'],
      ['breakpoints', 2, 'Show trace line numbers',
       'These are the line number where a breakpoint can be set.'],
      ['lines', 1, 'Show number of lines in the file'],
      ['mtime', 1, 'Show modification time of file'],
      ['path', 4, 'Show full file path name for file'],
      ['sha1', 1, 'Show SHA1 hash of contents of the file']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(InfoFileSubcommands)

    def info_file(*args)
      return info_files unless args[0]

      mode = args[1] || 'basic'
      subcmd = Command.find(InfoFileSubcommands, mode)
      return errmsg "Invalid parameter #{args[1]}\n" unless subcmd

      if %w(all basic).member?(subcmd.name)
        info_file_path(args[0])
        info_file_lines(args[0])
        if subcmd.name == 'all'
          info_file_breakpoints(args[0])
          info_file_mtime(args[0])
          info_file_sha1(args[0])
        end
      else
        puts("File #{args[0]}") if subcmd.name != 'path'
        send("info_file_#{subcmd.name}", args[0])
      end
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
