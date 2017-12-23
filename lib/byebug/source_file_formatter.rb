# frozen_string_literal: true

require 'byebug/helpers/file'
require 'byebug/setting'

module Byebug
  #
  # Formats specific line ranges in a source file
  #
  class SourceFileFormatter
    include Helpers::FileHelper

    attr_reader :file, :annotator

    def initialize(file, annotator)
      @file = file
      @annotator = annotator
    end

    def lines(min, max)
      File.foreach(file).with_index.map do |line, lineno|
        next unless (min..max).cover?(lineno + 1)

        annotation = annotator.call(lineno + 1)

        format("%s %#{max.to_s.size}d: %s", annotation, lineno + 1, line)
      end
    end

    def amend_initial(line)
      amend(line, max_initial_line)
    end

    def amend_final(line)
      amend(line, max_line)
    end

    def max_initial_line
      max_line - size + 1
    end

    def max_line
      @max_line ||= n_lines(file)
    end

    def size
      [Setting[:listsize], max_line].min
    end

    def amend(line, ceiling)
      [ceiling, [1, line].max].min
    end
  end
end
