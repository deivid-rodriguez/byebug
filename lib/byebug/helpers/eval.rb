module Byebug
  module Helpers
    #
    # Utilities to assist evaluation of code strings
    #
    module EvalHelper
      #
      # Evaluates +expression+ that might manipulate threads
      #
      # @param expression [String] Expression to evaluate
      #
      def thread_safe_eval(expression)
        allowing_other_threads { single_thread_eval(expression) }
      end

      #
      # Evaluates an +expression+ that doesn't deal with threads
      #
      # @param expression [String] Expression to evaluate
      #
      def single_thread_eval(expression)
        return error_eval(expression) if Setting[:stack_on_error]

        warning_eval(expression)
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # returning nil in an error happens.
      #
      def silent_eval(str, binding = default_binding)
        binding.eval(str)
      rescue StandardError, ScriptError
        nil
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # handling the errors at an error level.
      #
      def error_eval(str, binding = default_binding)
        safe_eval(str, binding) { |e| error_msg(e) }
      end

      #
      # Evaluates a string containing Ruby code in a specific binding,
      # handling the errors at a warning level.
      #
      def warning_eval(str, binding = default_binding)
        safe_eval(str, binding) { |e| warning_msg(e) }
      end

      def default_binding
        @state.context.frame_binding(@state.frame) if @state.context
      end

      private

      def safe_eval(str, binding)
        binding.eval(str)
      rescue StandardError, ScriptError => e
        yield(e)
      end

      def error_msg(e)
        at = e.backtrace
        locations = ["#{at.shift}: #{e.class} Exception(#{e.message})"]
        locations += at.map { |path| "\tfrom #{path}" }

        errmsg(locations.join("\n"))
      end

      def warning_msg(e)
        errmsg("#{e.class} Exception: #{e.message}")
      end

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
    end
  end
end
