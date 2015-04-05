module Byebug
  module Helpers
    #
    # Utilities for interaction with files
    #
    module FileHelper
      #
      # Reads lines of source file +filename+ into an array
      #
      def get_lines(filename)
        File.foreach(filename).reduce([]) { |a, e| a << e.chomp }
      end

      #
      # Reads line number +lineno+ from file named +filename+
      #
      def get_line(filename, lineno)
        File.open(filename) do |f|
          f.gets until f.lineno == lineno - 1
          f.gets
        end
      end

      #
      # Returns the number of lines in file +filename+ in a portable,
      # one-line-at-a-time way.
      #
      def n_lines(filename)
        File.foreach(filename).reduce(0) { |a, _e| a + 1 }
      end

      #
      # Regularize file name.
      #
      def normalize(filename)
        return filename if ['(irb)', '-e'].include?(filename)

        return File.basename(filename) if Setting[:basename]

        path = File.expand_path(filename)

        File.exist?(path) ? File.realpath(path) : filename
      end
    end
  end
end
