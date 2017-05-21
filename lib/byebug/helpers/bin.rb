module Byebug
  module Helpers
    #
    # Utilities for interaction with executables
    #
    module BinHelper
      #
      # Cross-platform way of finding an executable in the $PATH.
      # Borrowed from: http://stackoverflow.com/questions/2108727
      #
      def which(cmd)
        return File.expand_path(cmd) if File.exist?(cmd)

        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end

        nil
      end
    end
  end
end
