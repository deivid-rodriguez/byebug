module Byebug

  module VarFunctions
    def var_list(ary, b = get_binding)
      ary.sort!
      for v in ary
        begin
          s = bb_eval(v.to_s, b).inspect
        rescue
          begin
            s = bb_eval(v.to_s, b).to_s
          rescue
            s = "*Error in evaluation*"
          end
        end
        pad_with_dots(s)
        print "#{v} = #{s}\n"
      end
    end
    def var_class_self
      obj = bb_eval('self')
      var_list(obj.class.class_variables, get_binding)
    end
    def var_global
      var_list(global_variables.reject { |v| [:$=, :$KCODE, :$-K].include?(v) })
    end
  end

  # Implements byebug's 'var class' command
  class VarClassVarCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ cl(?:ass)? \s*/x
    end

    def execute
      unless @state.context
        errmsg "can't get class variables here.\n"
        return
      end
      var_class_self
    end

    class << self
      def names
        %w(var)
      end

      def description
        %{v[ar] cl[ass] \t\t\tshow class variables of self}
      end
    end
  end

  class VarConstantCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ co(?:nst(?:ant)?)? \s+/x
    end

    def execute
      obj = bb_eval(@match.post_match)
      if obj.kind_of? Module
        constants = bb_eval("#{@match.post_match}.constants")
        constants.sort!
        for c in constants
          next if c =~ /SCRIPT/
          value = obj.const_get(c) rescue "ERROR: #{$!}"
          print " %s => %p\n", c, value
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
        %{v[ar] co[nst] <object>\t\tshow constants of object}
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
        %{v[ar] g[lobal]\t\t\tshow global variables}
      end
    end
  end

  class VarInstanceCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ ins(?:tance)? \s*/x
    end

    def execute
      obj = bb_eval(@match.post_match.empty? ? 'self' : @match.post_match)
      var_list(obj.instance_variables, obj.instance_eval{binding()})
    end

    class << self
      def names
        %w(var)
      end

      def description
        %{v[ar] i[nstance] <object>\tshow instance variables of object}
      end
    end
  end

  # Implements byebug's 'var local' command
  class VarLocalCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ l(?:ocal)? \s*$/x
    end

    def execute
      _self = @state.context.frame_self(@state.frame_pos)
      locals = @state.context.frame_locals
      locals.keys.sort.each do |name|
        print "  %s => %p\n", name, locals[name]
      end
    end

    class << self
      def names
        %w(var)
      end

      def description
        %{v[ar] l[ocal]\t\t\tshow local variables}
      end
    end
  end

  begin
    require 'classtree'
    have_classtree = true
  rescue LoadError
    have_classtree = false
  end

  # Implements byebug's 'var inherit' command
  class VarInheritCommand < Command
    def regexp
      /^\s* v(?:ar)? \s+ ct \s*$/x
    end

    def execute
      unless @state.context
        errmsg "can't get object inheritance.\n"
        return
      end
      puts @match.post_match
      obj = bb_eval("#{@match.post_match}.classtree")
      if obj
        print obj
      else
        errmsg "Trouble getting object #{@match.post_match}\n"
      end
    end

    class << self
      def names
        %w(var)
      end

      def description
        %{v[ar] ct\t\t\tshow class heirarchy of object}
      end
    end
  end if have_classtree

end
