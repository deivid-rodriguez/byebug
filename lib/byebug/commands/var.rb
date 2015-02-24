require 'byebug/command'

module Byebug
  #
  # Utilities for the var command.
  #
  module VarFunctions
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

    def var_global(_str = nil)
      globals = global_variables.reject do |v|
        [:$IGNORECASE, :$=, :$KCODE, :$-K, :$binding].include?(v)
      end

      var_list(globals)
    end

    def var_instance(str)
      obj = bb_warning_eval(str || 'self')
      var_list(obj.instance_variables, obj.instance_eval { binding })
    end

    def var_constant(str)
      str ||= 'self.class'
      obj = bb_warning_eval(str)
      is_mod = obj.is_a?(Module)
      return errmsg(pr('variable.errors.not_module', object: str)) unless is_mod

      constants = bb_eval("#{str}.constants")
      puts prv(constants.sort.map { |c| [c, obj.const_get(c)] })
    end

    def var_local(_str = nil)
      _self = @state.context.frame_self(@state.frame)
      locals = @state.context.frame_locals
      puts prv(locals.keys.sort.map { |k| [k, locals[k]] })
    end

    def var_all(_str = nil)
      var_global
      var_instance('self')
      var_local
    end
  end

  #
  # Show variables and its values.
  #
  class VarCommand < Command
    include VarFunctions

    Subcommands = [
      ['constant', 2, 'Show constants of an object'],
      ['global', 1, 'Show global variables'],
      ['instance', 1, 'Show instance variables of self or a specific object'],
      ['local', 1, 'Show local variables in current scope'],
      ['all', 1, 'Shows local, global and instance variables of self']
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end

    def regexp
      /^\s* v(?:ar)? (?: \s+(\S+) (?:\s(\S+))? )? \s*$/x
    end

    def execute
      return puts(self.class.help) unless @match[1]

      subcmd = Command.find(Subcommands, @match[1])
      return errmsg("Unknown var command #{@match[1]}\n") unless subcmd

      if @state.context
        send("var_#{subcmd.name}", @match[2])
      else
        errmsg "'var #{subcmd.name}' not available without a context.\n"
      end
    end

    class << self
      def names
        %w(var)
      end

      def description
        prettify <<-EOD
          [v]ar

          Show variables and its values.
        EOD
      end
    end
  end
end
