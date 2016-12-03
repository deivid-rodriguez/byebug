module Byebug
  module Helpers
    #
    # Utilities for managing gem paths
    #
    module PathHelper
      def bin_file
        @bin_file ||= Gem.bin_path('byebug', 'byebug')
      end

      def root_path
        @root_path ||= File.expand_path('../..', bin_file)
      end

      def lib_files
        @lib_files ||= glob_for('lib')
      end

      def test_files
        @test_files ||= glob_for('test')
      end

      def gem_files
        @gem_files ||= [bin_file] + lib_files
      end

      def all_files
        @all_files ||= gem_files + test_files
      end

      private

      def glob_for(dir)
        Dir.glob(File.expand_path("#{dir}/**/*.rb", root_path))
      end
    end
  end
end
