require 'columnize'
require 'forwardable'
require 'byebug/helper'

module Byebug
  class Command
    Subcmd = Struct.new(:name, :min, :help)

    class << self
      attr_accessor :allow_in_control, :unknown
      attr_writer :allow_in_post_mortem, :always_run

      def allow_in_post_mortem
        @allow_in_post_mortem ||= !defined?(@allow_in_post_mortem) ? true : false
      end

      def always_run
        @always_run ||= 0
      end

      def help(args)
        if args && args[1]
          output = format_subcmd(args[1])
        else
          output = description.gsub(/^ +/, '') + "\n"
          output += format_subcmds if defined? self::Subcommands
        end
        output
      end

      def find(subcmds, param)
        param.downcase!
        for try_subcmd in subcmds do
          if (param.size >= try_subcmd.min) and
              (try_subcmd.name[0..param.size-1] == param)
            return try_subcmd
          end
        end
        return nil
      end

      def format_subcmd(subcmd_name)
        subcmd = find(self::Subcommands, subcmd_name)
        return "Invalid \"#{names.join("|")}\" " \
               "subcommand \"#{args[1]}\"." unless subcmd

        return "#{subcmd.help}.\n"
      end

      def format_subcmds
        cmd_name = names.join("|")
        s = "\n"                                     \
            "--\n"                                   \
            "List of \"#{cmd_name}\" subcommands:\n" \
            "--\n"
        w = self::Subcommands.map(&:name).max_by(&:size).size
        for subcmd in self::Subcommands do
          s += sprintf "%s %-#{w}s -- %s\n", cmd_name, subcmd.name, subcmd.help
        end
        return s
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

        Byebug.constants.grep(/Functions$/).map {
          |name| Byebug.const_get(name)
        }.each { |mod| include mod }
      end
    end

    def initialize(state)
      @match, @state = nil, state
    end

    def match(input)
      @match = regexp.match(input)
    end

    protected

      extend Forwardable
      def_delegators :@state, :errmsg, :print

      def confirm(msg)
        @state.confirm(msg) == 'y'
      end

      def bb_eval(str, b = get_binding)
        begin
          eval(str, b)
        rescue StandardError, ScriptError => e
          at = eval('Thread.current.backtrace_locations(1)', b)
          print "#{at.shift}: #{e.class} Exception(#{e.message})\n"
          for i in at
            print "\tfrom #{i}\n"
          end
          nil
        end
      end

      def bb_warning_eval(str, b = get_binding)
        begin
          eval(str, b)
        rescue StandardError, ScriptError => e
          print "#{e.class} Exception: #{e.message}\n"
          nil
        end
      end

      def get_binding pos = @state.frame_pos
        @state.context ? @state.context.frame_binding(pos) : TOPLEVEL_BINDING
      end

      def get_context(thnum)
        Byebug.contexts.find {|c| c.thnum == thnum}
      end
  end

  Command.load_commands
end
