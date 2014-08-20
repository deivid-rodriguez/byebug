module Byebug
  #
  # Interrupting execution of current thread.
  #
  class InterruptCommand < Command
    self.allow_in_control     = true
    self.allow_in_post_mortem = false

    def regexp
      /^\s*i(?:nterrupt)?\s*$/
    end

    def execute
      context = Byebug.thread_context(Thread.main)
      context.interrupt
    end

    class << self
      def names
        %w(interrupt)
      end

      def description
        %(i|nterrupt        Interrupts the program.)
      end
    end
  end
end
