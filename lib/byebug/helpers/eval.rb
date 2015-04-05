module Byebug
  module Helpers
    #
    # Utilities used by the eval command
    #
    module EvalHelper
      #
      # Run block temporarily ignoring all TracePoint events.
      #
      # Used to evaluate stuff within Byebug's prompt. Otherwise, any code
      # creating new threads won't be properly evaluated because new threads
      # will get blocked by byebug's main thread.
      #
      def allowing_other_threads
        Byebug.unlock
        res = yield
        Byebug.lock
        res
      end

      #
      # Get current binding and yield it to the given block
      #
      def run_with_binding
        binding = get_binding
        yield binding
      end

      #
      # Evaluate +expression+ using +binding+
      #
      # @param binding [Binding] Context where to evaluate the expression
      # @param expression [String] Expression to evaluation
      # @param stack_on_error [Boolean] Whether to show a stack trace on error.
      #
      def eval_with_setting(binding, expression, stack_on_error)
        allowing_other_threads do
          if stack_on_error
            bb_eval(expression, binding)
          else
            bb_warning_eval(expression, binding)
          end
        end
      end
    end
  end
end
