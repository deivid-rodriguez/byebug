module Byebug
  class MethodCommand < Command
    include Columnize

    def regexp
      /^\s* m(?:ethod)? \s+ (i(:?nstance)?\s+)?/x
    end

    def execute
      obj = bb_eval(@match.post_match)
      if @match[1]
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
          m[ethod] <class|module>\t\tshow instance methods of class or module}
      end
    end
  end
end
