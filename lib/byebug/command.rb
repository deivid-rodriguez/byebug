require 'columnize'
require 'forwardable'
require 'byebug/subcommand_list'
require 'byebug/helpers/string'

module Byebug
  #
  # Parent class of all byebug commands.
  #
  # Subclasses need to implement a `regexp` and an `execute` command.
  #
  class Command
    extend Forwardable

    include Helpers::StringHelper

    def initialize(state)
      @match, @state = nil, state
    end

    def match(input)
      @match = regexp.match(input)
    end

    #
    # Delegates to subcommands or prints help if no subcommand specified.
    #
    # If you implement a custom command (inheriting from `Byebug::Command`, you
    # want to either override this method or define subcommands.
    #
    def execute
      return puts(help) unless @match[1]

      subcmd = subcommands.find(@match[1])
      return errmsg("Unknown subcommand '#{@match[1]}'\n") unless subcmd

      subcmd.execute
    end

    def_delegators :'self.class', :to_name, :description

    #
    # Default help text for a command.
    #
    def help
      return help_with_subcommands if subcommands

      prettify(description)
    end

    #
    # Default help text for a command with subcommands
    #
    def help_with_subcommands
      prettify <<-EOH
        #{description}

        List of "#{to_name}" subcommands:

        --
        #{subcommands}
      EOH
    end

    #
    # Command's subcommands.
    #
    def subcommands
      subcmd_klasses = self.class.subcommands
      return nil unless subcmd_klasses.any?

      subcmd_list = subcmd_klasses.map { |cmd| cmd.new(@state) }
      SubcommandList.new(subcmd_list, self.class.name)
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
      attr_accessor :allow_in_control
      attr_writer :allow_in_post_mortem, :always_run

      def allow_in_post_mortem
        !defined?(@allow_in_post_mortem) ? true : false
      end

      def always_run
        @always_run ||= 0
      end

      #
      # Name of the command, as executed by the user.
      #
      def to_name
        name.gsub(/^Byebug::/, '').gsub(/Command$/, '').downcase
      end

      #
      # Description of the command
      #
      def description
        fail(NotImplementedError, 'Your custom command needs to define this')
      end

      #
      # Available subcommands for the current command
      #
      # A subcommand is a class inside the parent's command class named
      # <something>Subcommand.
      #
      def subcommands
        const_list = constants.map { |const| const_get(const, false) }

        const_list.select { |c| c.is_a?(Class) && c.name =~ /[a-z]Subcommand$/ }
      end
    end
  end
end
