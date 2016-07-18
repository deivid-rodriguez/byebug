require 'linecache2'
module Byebug
  module Helpers
    #
    # Utilities for interaction with files
    #
    module FileHelper
      #
      # Reads lines of source file +filename+ into an array
      #
      def get_lines(filename, opts = {})
        LineCache.getlines(filename, opts)
      end

      #
      # Reads line number +lineno+ from file named +filename+
      #
      def get_line(filename, lineno, opts = {})
        LineCache.getline(filename, lineno, opts)
      end

      #
      # Returns the number of lines in file +filename+ in a portable,
      # one-line-at-a-time way.
      #
      def n_lines(filename)
        LineCache.size(filename)
      end

      #
      # Regularize file name.
      #
      def normalize(filename)
        return filename if virtual_file?(filename)

        return File.basename(filename) if Setting[:basename]

        File.exist?(filename) ? File.realpath(filename) : filename
      end

      #
      # A short version of a long path
      #
      def shortpath(fullpath)
        components = Pathname(fullpath).each_filename.to_a
        return fullpath if components.size <= 2

        File.join('...', components[-3..-1])
      end

      #
      # True for special files like -e, false otherwise
      #
      def virtual_file?(name)
        ['(irb)', '-e', '(byebug)', '(eval)'].include?(name)
      end
    end
  end
end
