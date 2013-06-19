require 'irb'

module IRB
  module ExtendCommand
    class Continue
      def self.execute(conf)
        throw :IRB_EXIT, :cont
      end
    end
    class Next
      def self.execute(conf)
        throw :IRB_EXIT, :next
      end
    end
    class Step
      def self.execute(conf)
        throw :IRB_EXIT, :step
      end
    end
  end
  ExtendCommandBundle.def_extend_command "cont", :Continue
  ExtendCommandBundle.def_extend_command "n", :Next
  ExtendCommandBundle.def_extend_command "step", :Step

  def self.start_session(binding)
    unless @__initialized
      args = ARGV.dup
      ARGV.replace([])
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end

    workspace = WorkSpace.new(binding)
    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    trap("SIGINT") do
      irb.signal_handle
    end

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

module Byebug

  # Implements byebug's "irb" command.
  class IRBCommand < Command

    register_setting_get(:autoirb) do
      IRBCommand.always_run
    end
    register_setting_set(:autoirb) do |value|
      IRBCommand.always_run = value
    end

    def regexp
      /^\s* irb
        (?:\s+(-d))?
        \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      add_debugging = @match.is_a?(MatchData) && '-d' == @match[1]
      $byebug_state = @state if add_debugging

      cont = IRB.start_session(get_binding)
      case cont
      when :cont
        @state.proceed
      when :step
        force = Command.settings[:force_stepping]
        @state.context.step_into 1, force
        @state.proceed
      when :next
        force = Command.settings[:force_stepping]
        @state.context.step_over 1, @state.frame_pos, force
        @state.proceed
      else
        file = @state.context.frame_file(0)
        line = @state.context.frame_line(0)
        CommandProcessor.print_location_and_text(file, line)
        @state.previous_line = nil
      end
      $byebug_state = nil if add_debugging
    end


    class << self
      def names
        %w(irb)
      end

      def description
        %{irb[ -d]\tstarts an Interactive Ruby (IRB) session.

          If -d is added you can get access to byebug's state via the global
          variable $byebug_state. IRB is extended with methods "cont", "n" and
          "step" which run the corresponding byebug commands. In contrast to the
          real byebug commands these commands don't allow arguments.}
      end
    end
  end

  begin
    require 'pry'
    has_pry = true
  rescue LoadError
    has_pry = false
  end

  # Implements byebug's "pry" command
  class PryCommand < Command
    def regexp
      /^\s* pry
        (?:\s+(-d))?
        \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      add_debugging = @match.is_a?(MatchData) && '-d' == @match[1]
      $byebug_state = @state if add_debugging

      get_binding.pry

      $byebug_state = nil if add_debugging
    end

    class << self
      def names
        %w(pry)
      end

      def description
        %{pry[ -d]\tstarts a Pry session.}
      end
    end
  end if has_pry

end
