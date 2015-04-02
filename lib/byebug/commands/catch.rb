require 'byebug/command'

module Byebug
  #
  # Implements exception catching.
  #
  # Enables the user to catch unhandled assertion when they happen.
  #
  class CatchCommand < Command
    def regexp
      /^\s* cat(?:ch)? (?:\s+(\S+))? (?:\s+(off))? \s*$/x
    end

    def execute
      ex = @match[1]
      return info_catch unless ex

      cmd = @match[2]
      unless cmd
        if 'off' == ex
          Byebug.catchpoints.clear if
            confirm(pr('catch.confirmations.delete_all'))

          return
        end

        is_class = bb_eval("#{ex.is_a?(Class)}")
        puts pr('catch.errors.not_class', class: ex) unless is_class

        Byebug.add_catchpoint(ex)
        return puts pr('catch.catching', exception: ex)
      end

      if cmd == 'off'
        exists = Byebug.catchpoints.member?(ex)
        return errmsg pr('catch.errors.not_found', exception: ex) unless exists

        Byebug.catchpoints.delete(ex)
        return errmsg pr('catch.errors.removed', exception: ex)
      end

      errmsg pr('catch.errors.off', off: cmd)
    end

    class << self
      def names
        %w(catch)
      end

      def description
        prettify <<-EOD
          cat[ch][ (off|<exception>[ off])]

          "catch" lists catchpoints.
          "catch off" deletes all catchpoints.
          "catch <exception>" enables handling <exception>.
          "catch <exception> off" disables handling <exception>.
        EOD
      end
    end
  end
end
