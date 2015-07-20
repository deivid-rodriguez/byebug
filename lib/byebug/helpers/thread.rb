module Byebug
  module Helpers
    #
    # Utilities for thread subcommands
    #
    module ThreadHelper
      def display_context(ctx)
        puts pr('thread.context', thread_arguments(ctx))
      end

      def thread_arguments(ctx)
        status_flag = if ctx.suspended?
                        '$'
                      else
                        current_thread?(ctx) ? '+' : ' '
                      end

        debug_flag = ctx.ignored? ? '!' : ' '

        # Check whether it is Byebug.current_context or context
        if ctx == Byebug.current_context
          file_line = context.location
        else
          backtrace = ctx.thread.backtrace_locations
          if backtrace && backtrace[0]
            file_line = "#{backtrace[0].path}:#{backtrace[0].lineno}"
          end
        end

        {
          status_flag: status_flag,
          debug_flag: debug_flag,
          id: ctx.thnum,
          thread: ctx.thread.inspect,
          file_line: file_line || '',
          pid: Process.pid,
          status: ctx.thread.status,
          current: current_thread?(ctx)
        }
      end

      def current_thread?(ctx)
        ctx.thread == Thread.current
      end

      def context_from_thread(thnum)
        ctx = Byebug.contexts.find { |c| c.thnum.to_s == thnum }

        err = case
              when ctx.nil? then pr('thread.errors.no_thread')
              when ctx == context then pr('thread.errors.current_thread')
              when ctx.ignored? then pr('thread.errors.ignored', arg: thnum)
              end

        [ctx, err]
      end
    end
  end
end
