module Byebug
  #
  # List parts of the source code.
  #
  class ListCommand < Command
    def regexp
      /^\s* l(?:ist)? (?:\s*([-=])|\s+(\S+))? \s*$/x
    end

    def execute
      Byebug.source_reload if Setting[:autoreload]

      lines = get_lines(@state.file)
      return errmsg "No sourcefile available for #{@state.file}\n" unless lines

      @match ||= match('list')
      b, e = range(@match[2], lines.size)
      return errmsg('Invalid line range') unless valid_range?(b, e, lines.size)
      display_lines(b, e, lines)

      @state.prev_line = b
    end

    class << self
      def names
        %w(list)
      end

      def description
        %(l[ist][[-=]][ nn-mm]

          Lists lines of code forward from current line or from the place where
          code was last listed. If "list-" is specified, lists backwards
          instead. If "list=" is specified, lists from current line regardless
          of where code was last listed. A line range can also be specified to
          list specific sections of code.)
      end
    end

    private

    #
    # Line range to be printed by `list`.
    #
    # If <input> is set, range is parsed from it.
    #
    # Otherwise it's automatically chosen.
    #
    def range(input, max_line)
      size = [Setting[:listsize], max_line].min

      return set_range(size, max_line) unless input

      parse_range(input, size, max_line)
    end

    def valid_range?(first, last, max)
      first <= last && (1..max).include?(first) && (1..max).include?(last)
    end

    #
    # Set line range to be printed by list
    #
    # @param size - number of lines to be printed
    # @param max_line - max line number that can be printed
    #
    # @return first line number to list
    # @return last line number to list
    #
    def set_range(size, max_line)
      first = amend(lower(size, @match[1] || '+'), max_line - size + 1)

      [first, move(first, size - 1)]
    end

    def parse_range(input, size, max_line)
      first, err = get_int(input.split(/[-,]/)[0], 'List', 1, max_line)
      return [-1, -1] if err

      if input.split(/[-,]/)[1]
        last, _ = get_int(input.split(/[-,]/)[1], 'List', 1, max_line)
        return [-1, -1] unless last

        last = amend(last, max_line)
      else
        first -= (size / 2)
      end

      [first, last || move(first, size - 1)]
    end

    def amend(line, max_line)
      return 1 if line < 1

      [max_line, line].min
    end

    def lower(size, direction = '+')
      return @state.line - size / 2 if direction == '=' || !@state.prev_line

      move(@state.prev_line, size, direction)
    end

    def move(line, size, direction = '+')
      line.send(direction, size)
    end

    #
    # Show file lines in <lines> from line number <min> to line number <max>.
    #
    def display_lines(min, max, lines)
      puts "\n[#{min}, #{max}] in #{@state.file}"

      (min..max).to_a.zip(lines[min - 1..max - 1]).map do |l|
        mark = l[0] == @state.line ? '=> ' : '   '
        puts format("#{mark}%#{max.to_s.size}d: %s", l[0], l[1])
      end
    end
  end
end
