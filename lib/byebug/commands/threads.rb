module Byebug
  module ThreadFunctions
    def display_context(context, should_show_top_frame = true)
      args = thread_arguments(context, should_show_top_frame)
      print "%s%s%d %s\t%s\n", args[:status_flag], args[:debug_flag], args[:id],
                               args[:thread], args[:file_line]
    end

    def thread_arguments(context, should_show_top_frame = true)
      status_flag = if context.suspended?
        "$"
      else
        context.thread == Thread.current ? '+' : ' '
      end
      debug_flag = context.ignored? ? '!' : ' '
      if should_show_top_frame
        if context.thread == Thread.current && !context.dead?
          file = context.frame_file(0)
          line = context.frame_line(0)
        else
          if context.thread.backtrace_locations &&
             context.thread.backtrace_locations[0]
            file = context.thread.backtrace_locations[0].path
            line = context.thread.backtrace_locations[0].lineno
          end
        end
        file_line = "#{file}:#{line}"
      end
      {
        status_flag: status_flag,
        debug_flag: debug_flag,
        id: context.thnum,
        thread: context.thread.inspect,
        file_line: file_line ? file_line : ''
      }
    end

    def parse_thread_num(subcmd, arg)
      if '' == arg
        errmsg "\"#{subcmd}\" needs a thread number"
        nil
      else
        thread_num = get_int(arg, subcmd, 1)
        return nil unless thread_num
        get_context(thread_num)
      end
    end

    def parse_thread_num_for_cmd(subcmd, arg)
      c = parse_thread_num(subcmd, arg)
      return nil unless c
      case
      when nil == c
        errmsg 'No such thread'
      when @state.context == c
        errmsg "It's the current thread"
      when c.ignored?
        errmsg "Can't #{subcmd} thread #{arg}"
      else
        return c
      end
      return nil
    end

  end

  class ThreadListCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* th(?:read)? \s+ l(?:ist)? \s*$/x
    end

    def execute
      Byebug.contexts.select { |c| Thread.list.include?(c.thread) }
                     .sort_by(&:thnum).each { |c| display_context(c) }
    end

    class << self
      def names
        %w(thread)
      end

      def description
        %{
          th[read] l[ist]\t\t\tlist all threads
        }
      end
    end
  end

  class ThreadCurrentCommand < Command
    self.need_context = true

    def regexp
      /^\s* th(?:read)? \s+ (?:cur(?:rent)?)? \s*$/x
    end

    def execute
      display_context(@state.context)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        %{th[read] [cur[rent]]\t\tshow current thread}
      end
    end
  end

  class ThreadStopCommand < Command
    self.allow_in_control     = true
    self.allow_in_post_mortem = false
    self.need_context         = true

    def regexp
      /^\s* th(?:read)? \s+ stop \s* (\S*) \s*$/x
    end

    def execute
      c = parse_thread_num_for_cmd('thread stop', @match[1])
      return unless c
      c.suspend
      display_context(c)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        %{th[read] stop <nnn>\t\tstop thread nnn}
      end
    end
  end

  class ThreadResumeCommand < Command
    self.allow_in_control     = true
    self.allow_in_post_mortem = false
    self.need_context         = true

    def regexp
      /^\s* th(?:read)? \s+ resume \s* (\S*) \s*$/x
    end

    def execute
      c = parse_thread_num_for_cmd('thread resume', @match[1])
      return unless c
      if !c.suspended?
        errmsg 'Already running'
        return
      end
      c.resume
      display_context(c)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        %{th[read] resume <nnn>\t\tresume thread nnn}
      end
    end
  end

  class ThreadSwitchCommand < Command
    self.allow_in_control     = true
    self.allow_in_post_mortem = false
    self.need_context         = true

    def regexp
      /^\s* th(?:read)? \s+ (?:sw(?:itch)?\s+)? (\S+) \s*$/x
    end

    def execute
      if @match[1] =~ /switch/
        errmsg '"thread switch" needs a thread number'
        return
      end
      c = parse_thread_num_for_cmd('thread switch', @match[1])
      return unless c
      display_context(c)
      c.step_into 1
      c.thread.run
      @state.proceed
    end

    class << self
      def names
        %w(thread)
      end

      def description
        %{th[read] [sw[itch]] <nnn>\tswitch thread context to nnn}
      end
    end
  end
end
