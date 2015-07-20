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
      file, line = location(@match[1])
      return edit_error('not_exist', file) unless File.exist?(file)
      return edit_error('not_readable', file) unless File.readable?(file)

      cmd = line ? "#{editor} +#{line} #{file}" : "#{editor} #{file}"

      system(cmd)
    end

    def description
      <<-EOD
        edit[ file:lineno] Edit specified files.

        With no argument, edits file containing most recent line listed. Editing
        targets can also be specified to start editing at a specific line in a
        specific file.
      EOD
    end

    private

    def location(matched)
      if matched.nil?
        file = @state.file
        return errmsg(pr('edit.errors.state')) unless file
        line = @state.line
      elsif (@pos_match = /([^:]+)[:]([0-9]+)/.match(matched))
        file, line = @pos_match.captures
      else
        file = matched
        line = nil
      end

      [File.expand_path(file), line]
    end

    def editor
      ENV['EDITOR'] || 'vim'
    end

    def edit_error(type, file)
      errmsg(pr("edit.errors.#{type}", file: file))
    end
  end
end
