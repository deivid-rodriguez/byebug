module Byebug
  module Helpers
    #
    # Utilities for managing gem paths
    #
    module PathHelper
      def bin_file
        @bin_file ||= Gem.bin_path('byebug', 'byebug')
      end

      def lib_files
        @lib_files ||= Dir.glob(File.expand_path('../../../**/*.rb', __FILE__))
      end

      def all_files
        @all_files ||=
          Dir.glob(File.expand_path('../../../../**/*.rb', __FILE__))
      end
    end
  end
end
