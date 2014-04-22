module Byebug
  # Implements byebug's 'method' command.
  class MethodCommand < Command
    include Columnize

    def regexp
      /^\s* m(?:ethod)? \s+ ((iv)|(i(:?nstance)?)\s+)?/x
    end

    def execute
      obj = bb_eval(@match.post_match)
      if @match[1] == 'iv'
        obj.instance_variables.sort.each do |v|
          print "#{v} = #{obj.instance_variable_get(v).inspect}\n"
        end
      elsif @match[1]
        print "#{columnize(obj.methods.sort(), Setting[:width])}\n"
      elsif !obj.kind_of?(Module)
        print "Should be Class/Module: #{@match.post_match}\n"
      else
        print "#{columnize(obj.instance_methods(false).sort(), Setting[:width])}\n"
      end
    end

    class << self
      def names
        %w(method)
      end

      def description
        %{m[ethod] i[nstance] <obj>\tshow methods of object
          m[ethod] iv <obj>\t\tshow instance variables of object
          m[ethod] <class|module>\t\tshow instance methods of class or module}
      end
    end
  end
end
