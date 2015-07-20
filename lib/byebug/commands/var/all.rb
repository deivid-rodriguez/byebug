require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +all+ subcommand
  #
  class VarCommand < Command
    #
    # Shows global, instance and local variables
    #
    class AllSubcommand < Command
      include Helpers::VarHelper

      self.allow_in_post_mortem = true

      def regexp
        /^\s* a(?:ll)? \s*$/x
      end

      def description
        <<-EOD
          v[ar] a[ll]

          #{short_description}
        EOD
      end

      def short_description
        'Shows local, global and instance variables of self.'
      end

      def execute
        var_global
        var_instance('self')
        var_local
      end
    end
  end
end
