module Byebug
  module ThreadFunctions
    def display_context(context, should_show_top_frame = true)
      args = thread_arguments(context, should_show_top_frame)
      print "%s%s%d %s\t%s\n", args[:status_flag], args[:debug_flag], args[:id],
                               args[:thread], args[:file_line]
    end

    def thread_arguments(context, should_show_top_frame = true)
      is_current = context.thread == Thread.current
      status_flag = is_current ? '+' : ' '
      debug_flag = context.ignored? ? '!' : ' '
      if should_show_top_frame
        if context.thread == Thread.current
          file = context.frame_file(0)
          line = context.frame_line(0)
        else
          if context.thread.backtrace_locations && context.thread.backtrace_locations[0]
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
  end

  class ThreadListCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* th(?:read)? \s+ l(?:ist)? \s*$/x
    end

    def execute
      Byebug.contexts.sort_by(&:thnum).each { |c| display_context(c) }
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
end
