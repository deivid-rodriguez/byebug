require 'byebug/helpers/var'

module Byebug
  #
  # Reopens the +var+ command to define the +args+ subcommand
  #
  class VarCommand < Command
    #
    # Information about arguments of the current method/block
    #
    class ArgsSubcommand < Command
      include Helpers::VarHelper

      self.allow_in_post_mortem = true

      def regexp
        /^\s* a(?:rgs)? \s*$/x
      end

      def description
        <<-EOD
          v[ar] a[args]

          #{short_description}
        EOD
      end

      def short_description
        'Information about arguments of the current scope'
      end

      def execute
        var_args
      end
    end
  end
end
