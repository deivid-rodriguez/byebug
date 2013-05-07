module Byebug

  begin
    require 'methodsig'
    have_methodsig = true
  rescue LoadError
    have_methodsig = false
  end

  # Implements byebug's 'method sig' command.
  class MethodSigCommand < Command
    def regexp
      /^\s*m(?:ethod)?\s+sig(?:nature)?\s+(\S+)\s*$/
    end

    def execute
      obj = debug_eval('method(:%s)' % @match[1])
      if obj.is_a?(Method)
        begin
          print "%s\n", obj.signature.to_s
        rescue
          errmsg("Can't get signature for '#{@match[1]}'\n")
        end
      else
        errmsg("Can't make method out of '#{@match[1]}'\n")
      end
    end

    class << self
      def names
        %w(method)
      end

      def description
        %{
          m[ethod] sig[nature] <obj>\tshow the signature of a method
        }
      end
    end
  end if have_methodsig

  # Implements byebug's 'method' command.
  class MethodCommand < Command
    include Columnize

    def regexp
      /^\s*m(?:ethod)?\s+((iv)|(i(:?nstance)?)\s+)?/
    end

    def execute
      if @match[1] == "iv"
        obj = debug_eval(@match.post_match)
        obj.instance_variables.sort.each do |v|
          print "%s = %s\n", v, obj.instance_variable_get(v).inspect
        end
      elsif @match[1]
        obj = debug_eval(@match.post_match)
        print "%s\n", columnize(obj.methods.sort(), Command.settings[:width])
      else
        obj = debug_eval(@match.post_match)
        unless obj.kind_of? Module
          print "Should be Class/Module: %s\n", @match.post_match
        else
          print "%s\n", columnize(obj.instance_methods(false).sort(),
                                  Command.settings[:width])
        end
      end
    end

    class << self
      def names
        %w(method)
      end

      def description
        %{
          m[ethod] i[nstance] <obj>\tshow methods of object
          m[ethod] iv <obj>\t\tshow instance variables of object
          m[ethod] <class|module>\t\tshow instance methods of class or module
        }
      end
    end
  end

end
