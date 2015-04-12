module Byebug
  module Helpers
    #
    # Utilities for thread subcommands
    #
    module ThreadHelper
      def display_context(context)
        puts pr('thread.context', thread_arguments(context))
      end

      def thread_arguments(context)
        status_flag = if context.suspended?
                        '$'
                      else
                        context.thread == Thread.current ? '+' : ' '
                      end
        debug_flag = context.ignored? ? '!' : ' '

        if context == Byebug.current_context
          file_line = "#{@state.file}:#{@state.line}"
        else
          backtrace = context.thread.backtrace_locations
          if backtrace && backtrace[0]
            file_line = "#{backtrace[0].path}:#{backtrace[0].lineno}"
          end
        end

        {
          status_flag: status_flag,
          debug_flag: debug_flag,
          id: context.thnum,
          thread: context.thread.inspect,
          file_line: file_line || '',
          pid: Process.pid,
          status: context.thread.status,
          current: (context.thread == Thread.current)
        }
      end

      def context_from_thread(thnum)
        ctx = Byebug.contexts.find { |c| c.thnum.to_s == thnum }

        err = case
              when ctx.nil? then pr('thread.errors.no_thread')
              when ctx == @state.context then pr('thread.errors.current_thread')
              when ctx.ignored? then pr('thread.errors.ignored', arg: thnum)
              end

        [ctx, err]
      end
    end
  end
end
