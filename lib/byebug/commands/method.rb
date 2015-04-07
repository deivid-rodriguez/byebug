require 'byebug/command'

module Byebug
  #
  # Show methods of specific classes/modules/objects.
  #
  class MethodCommand < Command
    include Columnize

    def regexp
      /^\s* m(?:ethod)? \s+ (i(:?nstance)?\s+)?/x
    end

    def execute
      obj = bb_eval(@match.post_match)
      result =
        if @match[1]
          prc('method.methods', obj.methods.sort) { |item, _| { name: item } }
        elsif !obj.is_a?(Module)
          pr('variable.errors.not_module', object: @match.post_match)
        else
          prc('method.methods', obj.instance_methods(false).sort) do |item, _|
            { name: item }
          end
        end
      puts result
    end

    def description
      <<-EOD
        m[ethod] (i[nstance][ <obj>]|<class|module>)

        When invoked with "instance", shows instance methods of the object
        specified as argument or of self no object was specified.

        When invoked only with a class or module, shows class methods of the
        class or module specified as argument.
      EOD
    end
  end
end
