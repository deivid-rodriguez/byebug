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
        puts prv(vars, 'instance')
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
        cur_self = @state.context.frame_self(@state.frame)
        locals[:self] = cur_self unless cur_self.to_s == 'main'
        puts prv(locals.keys.sort.map { |k| [k, locals[k]] }, 'instance')
      end
    end
  end
end
