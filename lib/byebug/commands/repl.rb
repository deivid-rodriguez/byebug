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

  require 'irb'
  ExtendCommandBundle.def_extend_command "cont", :Continue
  ExtendCommandBundle.def_extend_command "n", :Next
  ExtendCommandBundle.def_extend_command "step", :Step

  def self.start_session(binding)
    unless @__initialized ||= false
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
      /^\s* irb \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      cont = IRB.start_session(get_binding)
      case cont
      when :cont
        @state.proceed
      when :step
        force = Command.settings[:forcestep]
        @state.context.step_into 1, force
        @state.proceed
      when :next
        force = Command.settings[:forcestep]
        @state.context.step_over 1, @state.frame_pos, force
        @state.proceed
      else
        print @state.location
        @state.previous_line = nil
      end
    end


    class << self
      def names
        %w(irb)
      end

      def description
        %{irb\tstarts an Interactive Ruby (IRB) session.

          IRB is extended with methods "cont", "n" and "step" which run the
          corresponding byebug commands. In contrast to the real byebug commands
          these commands don't allow arguments.}
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
      /^\s* pry \s*$/x
    end

    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      get_binding.pry
    end

    class << self
      def names
        %w(pry)
      end

      def description
        %{pry\tstarts a Pry session.}
      end
    end
  end if has_pry

end
