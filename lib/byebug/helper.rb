module Byebug
  #
  # Utilities for interaction with files
  #
  module FileFunctions
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

  #
  # Utilities for interaction with files
  #
  module StringFunctions
    #
    # Converts +str+ from an_underscored-or-dasherized_string to
    # ACamelizedString.
    #
    def camelize(str)
      str.dup.split(/[_-]/).map(&:capitalize).join('')
    end

    #
    # Improves indentation and spacing in +str+ for readability in Byebug's
    # command prompt.
    #
    def prettify(str)
      "\n" + str.gsub(/^ {8}/, '') + "\n"
    end
  end

  #
  # Utilities to assist command parsing
  #
  module ParseFunctions
    #
    # Parse 'str' of command 'cmd' as an integer between min and max. If either
    # min or max is nil, that value has no bound.
    #
    def get_int(str, cmd, min = nil, max = nil)
      if str !~ /\A[0-9]+\z/
        return nil, pr('parse.errors.int.not_number', cmd: cmd, str: str)
      end

      int = str.to_i
      if min && int < min
        return min, pr('parse.errors.int.too_low', cmd: cmd, str: str, min: min)
      elsif max && int > max
        return max, pr('parse.errors.int.too_high',
                       cmd: cmd, str: str, max: max)
      end

      int
    end

    #
    # Returns true if code is syntactically correct for Ruby
    #
    def syntax_valid?(code)
      return true unless code

      without_stderr do
        begin
          RubyVM::InstructionSequence.compile(code)
          true
        rescue SyntaxError
          false
        end
      end
    end

    #
    # Temporarily disable output to $stderr
    #
    def without_stderr
      stderr = $stderr
      $stderr.reopen(IO::NULL)

      yield
    ensure
      $stderr.reopen(stderr)
    end

    #
    # Returns the number of steps specified in <str> as an integer or 1 if <str>
    # is empty.
    #
    def parse_steps(str, cmd)
      return 1 unless str

      steps, err = get_int(str, cmd, 1)
      return nil, err unless steps

      steps
    end
  end
end
