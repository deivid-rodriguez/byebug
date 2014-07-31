module Byebug
  class DeleteCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    def regexp
      /^\s* del(?:ete)? (?:\s+(.*))?$/x
    end

    def execute
      return errmsg "We are not in a state we can delete breakpoints.\n" unless
        @state.context

      if not @match[1]
        Byebug.breakpoints.clear if confirm("Delete all breakpoints? (y or n) ")
      else
        @match[1].split(/[ \t]+/).each do |pos|
          return unless pos = get_int(pos, "Delete", 1)
          errmsg "No breakpoint number %d\n", pos unless
            Byebug.remove_breakpoint(pos)
        end
      end
    end

    class << self
      def names
        %w(delete)
      end

      def description
        %{del[ete][ nnn...]

          Without and argument, deletes all breakpoints. With integer arguments,
          it deletes specific breakpoints.}
      end
    end
  end
end
