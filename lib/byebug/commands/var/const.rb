module Byebug
  #
  # Reopens the +var+ command to define the +const+ subcommand
  #
  class VarCommand < Command
    #
    # Shows constants
    #
    class ConstSubcommand < Command
      def regexp
        /^\s* c(?:onst)? (?:\s+ (.+))? \s*$/x
      end

      def execute
        str_obj = @match[1] || 'self.class'
        obj = bb_warning_eval(str_obj)
        unless obj.is_a?(Module)
          return errmsg(pr('variable.errors.not_module', object: str_obj))
        end

        constants = bb_eval("#{str_obj}.constants")
        puts prv(constants.sort.map { |c| [c, obj.const_get(c)] }, 'constant')
      end

      def short_description
        'Shows constants of an object.'
      end

      def description
        <<-EOD
          v[ar] c[onstant]

          #{short_description}
        EOD
      end
    end
  end
end
