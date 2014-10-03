module Byebug
  #
  # Implements breakpoint functionality
  #
  class BreakCommand < Command
    self.allow_in_post_mortem = false
    self.allow_in_control = true

    POSITION_REGEXP = '(?:(\d+)|(.+?)[:.#]([^.:\s]+))'

    def regexp
      /^\s* b(?:reak)? (?:\s+ #{POSITION_REGEXP})? (?:\s+(.+))? \s*$/x
    end

    def execute
      return puts(self.class.help) if self.class.names.include?(@match[0])

      if @match[1]
        line, _, _, expr = @match.captures
      else
        _, file, line, expr = @match.captures
      end

      if expr && file.nil? && line.nil?
        return errmsg("Invalid breakpoint location: #{expr}")
      elsif expr && expr !~ /^\s*if\s+(.+)/
        return errmsg("Expecting \"if\" in breakpoint condition, got: #{expr}")
      else
        expr = $1
      end

      if file.nil? && !@state.context
        return errmsg('We are not in a state that has an associated file')
      end

      file = @state.file if file.nil?
      line = @state.line.to_s if line.nil?

      if line =~ /^\d+$/
        path = File.expand_path(file)
        file = CommandProcessor.canonic_file(file)
        return errmsg("No file named #{file}") unless File.exist?(path)

        l, n = line.to_i, File.foreach(path).count
        return errmsg("There are only #{n} lines in file #{file}") if l > n

        autoreload = Setting[:autoreload]
        possible_lines = LineCache.trace_line_numbers(path, autoreload)
        unless possible_lines.member?(l)
          return errmsg("Line #{l} is not a valid breakpoint in file #{file}")
        end

        b = Breakpoint.add(path, l, expr)
        puts "Created breakpoint #{b.id} at #{file}:#{l}"

        unless syntax_valid?(expr)
          errmsg("Incorrect expression \"#{expr}\"; breakpoint disabled.")
          b.enabled = false
        end

      else
        kl = bb_warning_eval(file)
        return errmsg("Unknown class #{file}") unless kl && kl.is_a?(Module)

        class_name, method = kl.name, line.intern
        b = Breakpoint.add(class_name, method, expr)
        puts "Created breakpoint #{b.id} at #{class_name}::#{method}"
      end
    end

    class << self
      def names
        %w(break)
      end

      def description
        <<-EOD.gsub(/^ {8}/, '')
          b[reak] file:line [if expr]
          b[reak] class(.|#)method [if expr]

          Set breakpoint to some position, (optionally) if expr == true
        EOD
      end
    end
  end
end
