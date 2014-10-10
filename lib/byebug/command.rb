require 'columnize'
require 'forwardable'
require 'byebug/helper'

module Byebug
  #
  # Parent class of all byebug commands.
  #
  # Subclasses need to implement a `regexp` and an `execute` command.
  #
  class Command
    extend Forwardable

    Subcmd = Struct.new(:name, :min, :help)

    def initialize(state)
      @match, @state = nil, state
    end

    def match(input)
      @match = regexp.match(input)
    end

    def_delegator :"Byebug.printer", :print, :pr
    def_delegator :"Byebug.printer", :print_collection, :prc
    def_delegator :"Byebug.printer", :print_variables, :prv

    protected

    def_delegators :@state, :errmsg, :puts, :print, :confirm

    def bb_eval(str, b = get_binding)
      b.eval(str)
    rescue StandardError, ScriptError => e
      at = b.eval('Thread.current.backtrace_locations')
      backtraces = []
      backtraces << "#{at.shift}: #{e.class} Exception(#{e.message})"
      backtraces += at.map { |path| puts "\tfrom #{path}" }
      errmsg(pr("eval.exception", text_message: backtraces.join("\n"), class: e.class, value: e.to_s))
      nil
    end

    def bb_warning_eval(str, b = get_binding)
      b.eval(str)
    rescue StandardError, ScriptError => e
      text_message = "#{e.class} Exception: #{e.message}"
      print(pr("eval.exception", text_message: text_message, class: e.class, value: e.to_s))
      nil
    end

    def get_binding(pos = @state.frame_pos)
      @state.context ? @state.context.frame_binding(pos) : TOPLEVEL_BINDING
    end

    class << self
      attr_accessor :allow_in_control
      attr_writer :allow_in_post_mortem, :always_run

      def allow_in_post_mortem
        !defined?(@allow_in_post_mortem) ? true : false
      end

      def always_run
        @always_run ||= 0
      end

      def help(args = nil)
        if args && args[1]
          output = format_subcmd(args[1])
        else
          output = description
          output += format_subcmds if defined? self::Subcommands
        end
        output
      end

      def find(subcmds, str)
        str.downcase!
        subcmds.each do |subcmd|
          if (str.size >= subcmd.min) && (subcmd.name[0..str.size - 1] == str)
            return subcmd
          end
        end

        nil
      end

      def format_subcmd(subcmd_name)
        subcmd = find(self::Subcommands, subcmd_name)
        return "Invalid \"#{names.join('|')}\" " \
               "subcommand \"#{args[1]}\"." unless subcmd

        "\n  #{subcmd.help}.\n\n"
      end

      def format_subcmds
        header = names.join('|')
        s = "  List of \"#{header}\" subcommands:\n  --\n"
        w = self::Subcommands.map(&:name).max_by(&:size).size
        self::Subcommands.each do |subcmd|
          s += format("  %s %-#{w}s -- %s\n", header, subcmd.name, subcmd.help)
        end
        s + "\n"
      end

      def commands
        @commands ||= []
      end

      def inherited(klass)
        commands << klass
      end

      def load_commands
        Dir.glob(File.expand_path('../commands/*.rb', __FILE__)).each do |file|
          require file
        end

        Byebug.constants.grep(/Functions$/).map do |name|
          include Byebug.const_get(name)
        end
      end
    end
  end

  Command.load_commands
end
