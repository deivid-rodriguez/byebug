module Byebug

  class Edit < Command
    self.allow_in_control = true

    def regexp
      /^\s* ed(?:it)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if not @match[1]
        unless @state.context
          errmsg "We are not in a state that has an associated file.\n"
          return
        end
        file = @state.file
        line_number = @state.line
      elsif @pos_match = /([^:]+)[:]([0-9]+)/.match(@match[1])
        file, line_number = @pos_match.captures
      else
        errmsg "Invalid file/line number specification: #{@match[1]}\n"
        return
      end
      editor = ENV['EDITOR'] || 'ex'
      if File.readable?(file)
        system("#{editor} +#{line_number} #{file}")
      else
        errmsg "File \"#{file}\" is not readable.\n"
      end
    end

    class << self
      def names
        %w(edit)
      end

      def description
        %{edit[ file:lineno]\tEdit specified file.

          With no argument, edits file containing most recent line listed.
          Editing targets can also be specified to start editing at a specific
          line in a specific file.}
      end
    end
  end

end
