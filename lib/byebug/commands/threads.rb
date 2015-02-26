require 'byebug/command'

#
# TODO: Implement thread commands as a single command with subcommands, just
# like `info`, `var`, `enable` and `disable`. This allows consistent help
# format and we can go back to showing help for a single command in the `help`
# command.
#
module Byebug
  #
  # Utilities to assist commands related to threads.
  #
  module ThreadFunctions
    def display_context(context, should_show_top_frame = true)
      puts pr('thread.context',
              thread_arguments(context, should_show_top_frame))
    end

    def thread_arguments(context, should_show_top_frame = true)
      status_flag = if context.suspended?
                      '$'
                    else
                      context.thread == Thread.current ? '+' : ' '
                    end
      debug_flag = context.ignored? ? '!' : ' '

      if should_show_top_frame
        if context == Byebug.current_context
          file_line = "#{@state.file}:#{@state.line}"
        else
          backtrace = context.thread.backtrace_locations
          if backtrace && backtrace[0]
            file_line = "#{backtrace[0].path}:#{backtrace[0].lineno}"
          end
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

  #
  # List current threads.
  #
  class ThreadListCommand < Command
    include ThreadFunctions

    self.allow_in_control = true

    def regexp
      /^\s* th(?:read)? \s+ l(?:ist)? \s*$/x
    end

    def execute
      contexts = Byebug.contexts.sort_by(&:thnum)

      thread_list = prc('thread.context', contexts) do |context, _|
        thread_arguments(context)
      end

      print(thread_list)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        prettify <<-EOD
          th[read] l[ist]  Lists all threads.
        EOD
      end
    end
  end

  #
  # Show current thread.
  #
  class ThreadCurrentCommand < Command
    include ThreadFunctions

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
        prettify <<-EOD
          th[read] cur[rent]  Shows current thread.
        EOD
      end
    end
  end

  #
  # Stop execution of a thread.
  #
  class ThreadStopCommand < Command
    include ThreadFunctions

    self.allow_in_control = true
    self.allow_in_post_mortem = false

    def regexp
      /^\s* th(?:read)? \s+ stop \s* (\S*) \s*$/x
    end

    def execute
      c, err = parse_thread_num_for_cmd('thread stop', @match[1])
      return errmsg(err) if err

      c.suspend
      display_context(c)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        prettify <<-EOD
          th[read] stop <n>  Stops thread <n>.
        EOD
      end
    end
  end

  #
  # Resume execution of a thread.
  #
  class ThreadResumeCommand < Command
    include ThreadFunctions

    self.allow_in_control = true
    self.allow_in_post_mortem = false

    def regexp
      /^\s* th(?:read)? \s+ resume \s* (\S*) \s*$/x
    end

    def execute
      c, err = parse_thread_num_for_cmd('thread resume', @match[1])
      return errmsg(err) if err
      return errmsg pr('thread.errors.already_running') unless c.suspended?

      c.resume
      display_context(c)
    end

    class << self
      def names
        %w(thread)
      end

      def description
        prettify <<-EOD
          th[read] resume <n>   Resumes thread <n>.
        EOD
      end
    end
  end

  #
  # Switch execution to a different thread.
  #
  class ThreadSwitchCommand < Command
    include ThreadFunctions

    self.allow_in_control = true
    self.allow_in_post_mortem = false

    def regexp
      /^\s* th(?:read)? \s+ sw(?:itch)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      c, err = parse_thread_num_for_cmd('thread switch', @match[1])
      return errmsg(err) if err

      display_context(c)

      c.switch
      @state.proceed
    end

    class << self
      def names
        %w(thread)
      end

      def description
        prettify <<-EOD
          th[read] sw[itch] <n>  Switches thread context to <n>.
        EOD
      end
    end
  end
end
