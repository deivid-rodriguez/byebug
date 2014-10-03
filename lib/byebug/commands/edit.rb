module Byebug
  #
  # Edit a file from byebug's prompt.
  #
  class EditCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* ed(?:it)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if !@match[1]
        unless @state.file
          return errmsg 'We are not in a state that has an associated file.'
        end
        file = @state.file
        line = @state.line if @state.line
      elsif (@pos_match = /([^:]+)[:]([0-9]+)/.match(@match[1]))
        file, line = @pos_match.captures
      elsif File.exist?(@match[1])
        file = @match[1]
      else
        return errmsg "Invalid file[:line] number specification: #{@match[1]}"
      end

      editor = ENV['EDITOR'] || 'vim'

      return \
        errmsg("File \"#{file}\" is not readable.") unless File.readable?(file)

      cmd = line ? "#{editor} +#{line} #{file}" : "#{editor} #{file}"

      system(cmd)
    end

    class << self
      def names
        %w(edit)
      end

      def description
        %(edit[ file:lineno]        Edit specified files.

          With no argument, edits file containing most recent line listed.
          Editing targets can also be specified to start editing at a specific
          line in a specific file.)
      end
    end
  end
end
