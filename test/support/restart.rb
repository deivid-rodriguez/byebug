# frozen_string_literal: true

#
# Common utilities for restart tests
#
module Byebug
  module RestartTestHelpers
    def setup
      super

      example_file.write(restart_tracer)
      example_file.close
    end

    private

    def restart_tracer
      deindent <<-'RUBY', leading_spaces: 8
        #!/usr/bin/env ruby

        require 'English'
        require 'byebug'

        byebug

        if $ARGV.empty?
          print "Run program #{$PROGRAM_NAME} with no args"
        else
          print "Run program #{$PROGRAM_NAME} with args #{$ARGV.join(',')}"
        end
      RUBY
    end

    def byebug_bin
      Context.bin_file
    end
  end
end
