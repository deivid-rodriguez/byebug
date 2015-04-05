module Byebug
  module Helpers
    #
    # Utilities for variable subcommands
    #
    module VarHelper
      def var_list(ary, b = get_binding)
        vars = ary.sort.map do |v|
          s = begin
            b.eval(v.to_s).inspect
          rescue
            begin
              b.eval(v.to_s).to_s
            rescue
              '*Error in evaluation*'
            end
          end
          [v, s]
        end
        puts prv(vars)
      end

      def var_global
        globals = global_variables.reject do |v|
          [:$IGNORECASE, :$=, :$KCODE, :$-K, :$binding].include?(v)
        end

        var_list(globals)
      end

      def var_instance(str)
        obj = bb_warning_eval(str || 'self')

        var_list(obj.instance_variables, obj.instance_eval { binding })
      end

      def var_local
        locals = @state.context.frame_locals

        puts prv(locals.keys.sort.map { |k| [k, locals[k]] })
      end
    end
  end
end
