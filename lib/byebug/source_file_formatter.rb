# frozen_string_literal: true

module Byebug
  #
  # Formats specific line ranges in a source file
  #
  class SourceFileFormatter
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
  end
end
