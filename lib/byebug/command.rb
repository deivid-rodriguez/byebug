require 'forwardable'
require 'byebug/helpers/string'

module Byebug
  #
  # Parent class of all byebug commands.
  #
  # Subclasses need to implement a `regexp` method and an `execute` method.
  #
  class Command
    extend Forwardable

    include Helpers::StringHelper

    def initialize(state)
      @match = nil
      @state = state
    end

    def match(input)
      @match = regexp.match(input)
    end

    def_delegators :'self.class', :to_name, :description

    #
    # Default help text for a command.
    #
    def help
      prettify(description)
    end

    def_delegator :"Byebug.printer", :print, :pr
    def_delegator :"Byebug.printer", :print_collection, :prc
    def_delegator :"Byebug.printer", :print_variables, :prv

    protected

    def_delegators :@state, :errmsg, :puts, :print, :confirm

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
      # Available subcommands for the current command
      #
      # A subcommand is any class defined inside the parent's command class
      #
      def subcommands
        const_list = constants(false).map { |const| const_get(const, false) }

        const_list.select { |c| c.is_a?(Class) }
      end
    end
  end
end
