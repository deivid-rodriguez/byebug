require 'byebug/helpers/file'

module Byebug
  #
  # Reopens the +info+ command to define the +file+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about a particular source file
    #
    class FileSubcommand < Command
      include Helpers::FileHelper

      def regexp
        /^\s* f(?:ile)? (?:\s+ (\S+))? \s*$/x
      end

      def execute
        file = @match[1] || @state.file
        unless File.exist?(file)
          return errmsg(pr('info.errors.undefined_file', file: file))
        end

        puts <<-EOC.gsub(/^ {6}/, '')

          File #{info_file_basic(file)}

          Breakpoint line numbers:
          #{info_file_breakpoints(file)}

          Modification time: #{info_file_mtime(file)}

          Sha1 Signature: #{info_file_sha1(file)}

        EOC
      end

      def short_description
        'Information about a particular source file.'
      end

      def description
        <<-EOD
          inf[o] f[ile]

          #{short_description}

          It informs about file name, number of lines, possible breakpoints in
          the file, last modification time and sha1 digest.
        EOD
      end

      private

      def info_file_basic(file)
        path = File.expand_path(file)
        return unless File.exist?(path)

        s = n_lines(path) == 1 ? '' : 's'
        "#{path} (#{n_lines(path)} line#{s})"
      end

      def info_file_breakpoints(file)
        breakpoints = Breakpoint.potential_lines(file)
        return unless breakpoints

        breakpoints.to_a.sort.columnize(line_prefix: '  ',
                                        displaywidth: Setting[:width])
      end

      def info_file_mtime(file)
        File.stat(file).mtime
      end

      def info_file_sha1(file)
        require 'digest/sha1'
        Digest::SHA1.hexdigest(file)
      end
    end
  end
end
