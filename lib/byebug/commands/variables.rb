module Byebug
  module VarFunctions
    def var_list(ary, b = get_binding)
      ary.sort!
      ary.each do |v|
        begin
          s = bb_eval(v.to_s, b).inspect
        rescue
          begin
            s = bb_eval(v.to_s, b).to_s
          rescue
            s = '*Error in evaluation*'
          end
        end
        s = "#{v} = #{s}"
        s[Setting[:width] - 3..-1] = '...' if s.size > Setting[:width]
        print "#{s}\n"
      end
    end

    def var_class_self
      obj = bb_eval('self')
      var_list(obj.class.class_variables, get_binding)
    end

    def var_global
      globals = global_variables.reject do |v|
        [:$IGNORECASE, :$=, :$KCODE, :$-K].include?(v)
      end

      var_list(globals)
    end

    def var_instance(where)
      obj = bb_eval(where)
      var_list(obj.instance_variables, obj.instance_eval { binding })
    end

    def var_local
      _self = @state.context.frame_self(@state.frame_pos)
      locals = @state.context.frame_locals
      locals.keys.sort.each do |name|
        interp = format("  %s => %p", name, locals[name])
        print("#{interp}\n")
      end
    end
  end

  class VarAllCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ a(?:ll)? \s*$/x
    end

    def execute
      var_class_self
      var_global
      var_instance('self')
      var_local
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] a[ll]

          Show local, global and instance & class variables of self.)
      end
    end
  end

  class VarClassCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ cl(?:ass)? \s*/x
    end

    def execute
      return errmsg "can't get class variables here.\n" unless @state.context
      var_class_self
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] cl[ass]        Show class variables of self.)
      end
    end
  end

  class VarConstantCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ co(?:nst(?:ant)?)? \s+/x
    end

    def execute
      obj = bb_eval(@match.post_match)
      if obj.is_a? Module
        constants = bb_eval("#{@match.post_match}.constants")
        constants.sort!
        constants.each do |c|
          next if c =~ /SCRIPT/
          value = obj.const_get(c) rescue "ERROR: #{$ERROR_INFO}"
          interp = format(" %s => %p", c, value)
          print("#{interp}\n")
        end
      else
        print "Should be Class/Module: #{@match.post_match}\n"
      end
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] co[nst] <object>        Show constants of <object>.)
      end
    end
  end

  class VarGlobalCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ g(?:lobal)? \s*$/x
    end

    def execute
      var_global
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] g[lobal]        Show global variables.)
      end
    end
  end

  class VarInstanceCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ ins(?:tance)? \s*/x
    end

    def execute
      var_instance(@match.post_match.empty? ? 'self' : @match.post_match)
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] i[nstance] <object>

        Show instance variables of <object>.)
      end
    end
  end

  class VarLocalCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ l(?:ocal)? \s*$/x
    end

    def execute
      var_local
    end

    class << self
      def names
        %w(var)
      end

      def description
        %(v[ar] l[ocal]        Sow local variables.)
      end
    end
  end
end
