module Mocha
  class Expectation

    # Allows to specify a block to execute when expectation will be matched.
    # This way, we can specify dynamic values to return or just make some side effects
    #
    # Example:
    #
    #   foo.expects(:bar).with('bla').calls { 2 + 3 }
    #   foo.bar('bla') # => 5
    #
    def calls(&block)
      @calls ||= Call.new
      @calls += Call.new(block)
      self
    end

    def invoke_with_calls(arguments, &block)
      invoke_without_calls(&block) || (@calls.next(arguments, &block) if @calls)
    end
    alias_method :invoke_without_calls, :invoke
    alias_method :invoke, :invoke_with_calls

  end

  class Mock

    # We monkey-patch that method to be able to pass arguments to Expectation#invoke method
    def method_missing(symbol, *arguments, &block)
      if @responder and not @responder.respond_to?(symbol)
        raise NoMethodError, "undefined method `#{symbol}' for #{self.mocha_inspect} which responds like #{@responder.mocha_inspect}"
      end
      if matching_expectation_allowing_invocation = @expectations.match_allowing_invocation(symbol, *arguments)
        # We change this line - added arguments
        matching_expectation_allowing_invocation.invoke(arguments, &block)
      else
        if (matching_expectation = @expectations.match(symbol, *arguments)) || (!matching_expectation && !@everything_stubbed)
          # We change this line - added arguments
          matching_expectation.invoke(arguments, &block) if matching_expectation
          message = UnexpectedInvocation.new(self, symbol, *arguments).to_s
          require 'mocha/mockery'
          message << Mockery.instance.mocha_inspect
          raise ExpectationError.new(message, caller)
        end
      end
    end

  end

  class Call

    attr_reader :blocks

    def initialize(*blocks)
      @blocks = [ *blocks ]
    end

    def next(arguments, &block)
      case @blocks.length
        when 0 then nil
        when 1 then @blocks.first.call(*arguments, &block)
        else @blocks.shift.call(*arguments, &block)
      end
    end

    def +(other)
      self.class.new(*(@blocks + other.blocks))
    end

  end
end
