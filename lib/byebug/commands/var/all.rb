require 'byebug/subcommand'
require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +all+ subcommand
  #
  class VarCommand < Command
    #
    # Shows global, instance and local variables
    #
    class AllSubcommand < Subcommand
      include Helpers::VarHelper

      def regexp
        /^\s* a(?:ll)? \s*$/x
      end

      def execute
        var_global
        var_instance('self')
        var_local
      end

      def self.short_description
        'Shows local, global and instance variables of self.'
      end

      def self.description
        <<-EOD
          v[ar] a[ll]

          #{short_description}
        EOD
      end
    end
  end
end
