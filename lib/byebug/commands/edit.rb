require 'byebug/command'

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
        return errmsg(pr('edit.errors.state')) unless @state.file
        file = @state.file
        line = @state.line if @state.line
      elsif (@pos_match = /([^:]+)[:]([0-9]+)/.match(@match[1]))
        file, line = @pos_match.captures
      else
        file = @match[1]
      end

      editor = ENV['EDITOR'] || 'vim'
      file = File.expand_path(file)

      unless File.exist?(file)
        return errmsg(pr('edit.errors.not_exist', file: file))
      end
      unless File.readable?(file)
        return errmsg(pr('edit.errors.not_readable', file: file))
      end

      cmd = line ? "#{editor} +#{line} #{file}" : "#{editor} #{file}"

      system(cmd)
    end

    class << self
      def names
        %w(edit)
      end

      def description
        prettify <<-EOD
          edit[ file:lineno] Edit specified files.

          With no argument, edits file containing most recent line listed.
          Editing targets can also be specified to start editing at a specific
          line in a specific file.
        EOD
      end
    end
  end
end
