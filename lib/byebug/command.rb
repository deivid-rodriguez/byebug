require 'columnize'
require 'forwardable'
require_relative 'helper'

module Byebug

  module CommandFunctions
    #
    # Pad a string with dots at the end to fit :width setting
    #
    def pad_with_dots(string)
      if string.size > Command.settings[:width]
        string[Command.settings[:width]-3 .. -1] = "..."
      end
    end
  end

  class Command
    Subcmd = Struct.new(:name, :min, :help)

    class << self
      def commands
        @commands ||= []
      end

      attr_accessor :allow_in_control, :unknown, :need_context
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

      def inherited(klass)
        commands << klass
      end

      def load_commands
        Dir[File.join(File.dirname(__FILE__), 'commands', '*')].each {
          |file| require file }
        Byebug.constants.grep(/Functions$/).map {
          |name| Byebug.const_get(name) }.each { |mod| include mod }
      end

      def settings_map
        @@settings_map ||= {}
      end
      private :settings_map

      def settings
        unless defined? @settings and @settings
          @settings = Object.new
          map = settings_map
          c = class << @settings; self end
          c.send(:define_method, :[]) do |name|
            raise "No such setting #{name}" unless map.has_key?(name)
            map[name][:getter].call
          end
          c.send(:define_method, :[]=) do |name, value|
            raise "No such setting #{name}" unless map.has_key?(name)
            map[name][:setter].call(value)
          end
        end
        @settings
      end

      def register_setting_var(name, default)
        var_name = "@@#{name}"
        class_variable_set(var_name, default)
        register_setting_get(name) { class_variable_get(var_name) }
        register_setting_set(name) { |value| class_variable_set(var_name, value) }
      end

      def register_setting_get(name, &block)
        settings_map[name] ||= {}
        settings_map[name][:getter] = block
      end

      def register_setting_set(name, &block)
        settings_map[name] ||= {}
        settings_map[name][:setter] = block
      end

      def command_exists?(command)
        ENV['PATH'].split(File::PATH_SEPARATOR).any? {
          |d| File.exist? File.join(d, command) }
      end

      def terminal_width
        if ENV['COLUMNS'] =~ /^\d+$/
          ENV['COLUMNS'].to_i
        elsif STDIN.tty? && command_exists?('stty')
          `stty size`.scan(/\d+/)[1].to_i
        else
          nil
        end
      end
    end

    # Register default settings
    register_setting_var(:basename, false)
    register_setting_var(:callstyle, :long)
    register_setting_var(:testing, false)
    register_setting_var(:forcestep, false)
    register_setting_var(:fullpath, true)
    register_setting_var(:listsize, 10)
    register_setting_var(:stack_on_error, false)
    register_setting_var(:linetrace_plus, false)
    cols = terminal_width || 160
    register_setting_var(:width, cols > 10 ? cols : 160)
    Byebug::ARGV = ARGV.clone unless defined? Byebug::ARGV
    register_setting_var(:argv, Byebug::ARGV)

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

  ##
  # Returns ths settings object.
  # Use Byebug.settings[] and Byebug.settings[]= methods to query and set
  # byebug settings. These settings are available:
  #
  #  :autoeval          - evaluates input in the current binding if it's not
  #                       recognized as a byebug command
  #  :autoirb           - automatically calls 'irb' command on breakpoint
  #  :autolist          - automatically calls 'list' command on breakpoint
  #  :autoreload        - makes 'list' command always display up-to-date source
  #                       code
  #  :frame_class_names - displays method's class name when showing frame stack
  #  :forcestep         - stepping command always move to the new line
  #  :fullpath          - displays full paths when showing frame stack
  #  :stack_on_error    - shows full stack trace if eval command results in an
  #                       exception
  #
  def self.settings
    Command.settings
  end
end
