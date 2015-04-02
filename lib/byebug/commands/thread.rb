require 'byebug/command'

module Byebug
  #
  # Manipulation of Ruby threads
  #
  class ThreadCommand < Command
    Subcommands = [
      ['current', 1, 'Shows current thread'],
      ['list', 1, 'Lists all threads'],
      ['resume', 1, 'Resumes execution of specified thread number'],
      ['stop', 2, 'Stops execution of specified thread number'],
      ['switch', 2, 'Switches execution to specified thread']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end

    def regexp
      /^\s* th(?:read)? (?:\s+ (.+))? \s*$/x
    end

    def execute
      return puts(self.class.help) unless @match[1]

      name, thnum = @match[1].split(/ +/)[0..1]
      subcmd = Command.find(Subcommands, name)
      return errmsg("Unknown thread command '#{name}'\n") unless subcmd

      send("thread_#{subcmd.name}", thnum)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        prettify <<-EOD
          Commands to manipulate threads.
        EOD
      end
    end

    private

    def thread_list(thnum)
      return errmsg("thread list doesn't need params") unless thnum.nil?

      contexts = Byebug.contexts.sort_by(&:thnum)

      thread_list = prc('thread.context', contexts) do |context, _|
        thread_arguments(context)
      end

      print(thread_list)
    end

    def thread_current(thnum)
      return errmsg("thread current doesn't need params") unless thnum.nil?

      display_context(@state.context)
    end

    def thread_stop(thnum)
      ctx, err = parse_thread_num_for_cmd('thread stop', thnum)
      return errmsg(err) if err

      ctx.suspend
      display_context(ctx)
    end

    def thread_resume(thnum)
      ctx, err = parse_thread_num_for_cmd('thread resume', thnum)
      return errmsg(err) if err
      return errmsg(pr('thread.errors.already_running')) unless ctx.suspended?

      ctx.resume
      display_context(ctx)
    end

    def thread_switch(thnum)
      ctx, err = parse_thread_num_for_cmd('thread switch', thnum)
      return errmsg(err) if err

      display_context(ctx)

      ctx.switch
      @state.proceed
    end

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
        file_line: file_line || ''
      }
    end

    def parse_thread_num(subcmd, arg)
      thnum, err = get_int(arg, subcmd, 1)
      return [nil, err] unless thnum

      Byebug.contexts.find { |c| c.thnum == thnum }
    end

    def parse_thread_num_for_cmd(subcmd, arg)
      c, err = parse_thread_num(subcmd, arg)

      case
      when err
        [c, err]
      when c.nil?
        [nil, pr('thread.errors.no_thread')]
      when @state.context == c
        [c, pr('thread.errors.current_thread')]
      when c.ignored?
        [c, pr('thread.errors.wrong_action', subcmd: subcmd, arg: arg)]
      else
        [c, nil]
      end
    end
  end
end
