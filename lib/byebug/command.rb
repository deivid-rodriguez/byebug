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
    Subcmd = Struct.new(:name, :min, :help)

    def initialize(state)
      @match, @state = nil, state
    end

    def match(input)
      @match = regexp.match(input)
    end

    protected

    extend Forwardable
    def_delegators :@state, :errmsg, :puts

    def confirm(msg)
      @state.confirm(msg) == 'y'
    end

    def bb_eval(str, b = get_binding)
      eval(str, b)
    rescue StandardError, ScriptError => e
      at = eval('Thread.current.backtrace_locations', b)
      puts "#{at.shift}: #{e.class} Exception(#{e.message})"
      at.each { |path| puts "\tfrom #{path}" }
      nil
    end

    def bb_warning_eval(str, b = get_binding)
      eval(str, b)
    rescue StandardError, ScriptError => e
      puts "#{e.class} Exception: #{e.message}"
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
          output = description.gsub(/^ +/, '') + "\n"
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
