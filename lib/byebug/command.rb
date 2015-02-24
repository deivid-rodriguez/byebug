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

    include ParseFunctions
    include FileFunctions

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

    #
    # Evaluates a string containing Ruby code, using binding +b+. In case of
    # error full stack trace and error are printed.
    #
    def bb_eval(str, b = get_binding)
      b.eval(str)
    rescue StandardError, ScriptError => e
      at = e.backtrace
      locations = []
      locations << "#{at.shift}: #{e.class} Exception(#{e.message})"
      locations += at.map { |path| "\tfrom #{path}" }

      errmsg(pr('eval.exception', text_message: locations.join("\n")))
      nil
    end

    #
    # Evaluates a string containing Ruby code, using binding +b+. In case of
    # error, an error message with the exception is printed.
    #
    def bb_warning_eval(str, b = get_binding)
      b.eval(str)
    rescue StandardError, ScriptError => e
      text_message = "#{e.class} Exception: #{e.message}"
      errmsg(pr('eval.exception', text_message: text_message))
      nil
    end

    def get_binding(pos = @state.frame)
      @state.context ? @state.context.frame_binding(pos) : TOPLEVEL_BINDING
    end

    class << self
      include StringFunctions

      attr_accessor :allow_in_control
      attr_writer :allow_in_post_mortem, :always_run

      def allow_in_post_mortem
        !defined?(@allow_in_post_mortem) ? true : false
      end

      def always_run
        @always_run ||= 0
      end

      def help(subcmd = nil)
        return format_subcmd(subcmd) if subcmd

        output = description
        output += format_subcmds if defined? self::Subcommands
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
    end
  end
end
