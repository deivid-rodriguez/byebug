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
      unless lines
        errmsg "No sourcefile available for #{@state.file}\n"
        return @state.previous_line
      end

      b, e = set_line_range(Setting[:listsize], lines.size)
      return @state.previous_line if b < 0

      display_lines(b, e, lines)

      @state.previous_line = b > lines.size ? @previous_line : b
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

    ##
    # Set line range to be printed by list
    #
    # @param listsize - number of lines to be printed
    # @param maxline - max line number that can be printed
    #
    def set_line_range(listsize, maxline)
      if !@match || !(@match[1] || @match[2])
        b = if @state.previous_line
              @state.previous_line + listsize
            else
              @state.line - (listsize / 2)
            end
      elsif @match[1] == '-'
        b = if @state.previous_line
              if  @state.previous_line > 0
                @state.previous_line - listsize
              else
                @state.previous_line
              end
            else
              @state.line - (listsize / 2)
            end
      elsif @match[1] == '='
        @state.previous_line = nil
        b = @state.line - (listsize / 2)
      else
        b, e = @match[2].split(/[-,]/)
        if e
          b = b.to_i
          e = e.to_i
        else
          b = b.to_i - (listsize / 2)
        end
      end

      if b > maxline
        errmsg 'Invalid line range'
        return [-1, -1]
      end

      b = [1, b].max
      e ||=  b + listsize - 1

      if e > maxline
        e = maxline
        b = e - listsize + 1
        b = [1, b].max
      end

      [b, e]
    end

    #
    # Show file lines in <lines> from line number <min> to line number <max>.
    #
    def display_lines(min, max, lines)
      puts "\n[#{min}, #{max}] in #{@state.file}"

      (min..max).to_a.zip(lines[min-1..max-1]).map do |l|
        mark = l[0] == @state.line ? '=> ' : '   '
        puts format("#{mark}%#{max.to_s.size}d: %s", l[0], l[1])
      end
    end
  end
end
