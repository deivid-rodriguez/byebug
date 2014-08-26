module Byebug
  #
  # Implements breakpoint deletion.
  #
  class DeleteCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    def regexp
      /^\s* del(?:ete)? (?:\s+(.*))?$/x
    end

    def execute
      unless @match[1]
        Byebug.breakpoints.clear if confirm('Delete all breakpoints? (y/n) ')

        return nil
      end

      @match[1].split(/[ \t]+/).each do |number|
        pos, err = get_int(number, 'Delete', 1)

        return errmsg(err) unless pos

        unless Breakpoint.remove(pos)
          return errmsg("No breakpoint number #{pos}")
        end
      end
    end

    class << self
      def names
        %w(delete)
      end

      def description
        %(del[ete][ nnn...]

          Without and argument, deletes all breakpoints. With integer
          arguments, it deletes specific breakpoints.)
      end
    end
  end
end
