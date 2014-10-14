module Byebug
  #
  # Read and cache lines of source code files
  #
  # Allows to get contents of files, caching lines on first access to the file.
  #
  module Filecache
    unless defined?(FilecacheInfo)
      FilecacheInfo = Struct.new(:numbers, :lines, :size, :mtime)
    end

    #
    # The file cache: key is a file name, value is a Filecache object
    #
    @file_cache = {}

    #
    # Clears the file cache entirely
    #
    def clear
      @file_cache = {}
    end
    module_function :clear

    #
    # Returns an array of cached file names
    #
    def cached_files
      @file_cache.keys
    end
    module_function :cached_files

    #
    # Cache filename if it's not already cached
    #
    # Returns the LineCacheInfo object or nil if file doesn't exist.
    #
    def cache(filename, reload_on_change = true)
      filename = File.expand_path(filename)
      return delete(filename) unless File.exist?(filename)

      return update(filename) unless @file_cache[filename]

      return @file_cache[filename] unless reload_on_change

      return update(filename) unless updated?(filename)

      @file_cache[filename]
    end
    module_function :cache

    #
    # Gets line <line_number> from file named <filename>.
    #
    # If <filename> was previously cached and <reload_on_change> is true, use
    # the results from the cache.
    #
    def line(filename, line_number, reload_on_change = true)
      all_lines = lines(filename, reload_on_change)
      return unless all_lines

      all_lines[line_number - 1] if (1..all_lines.size).include?(line_number)
    end
    module_function :line

    #
    # Reads lines of <filename> and cache the results.
    #
    # If <filename> was previously cached and <reload_on_change> is true, use
    # the results from the cache.
    #
    def lines(filename, reload_on_change = true)
      cached_file = cache(filename, reload_on_change)

      cached_file.lines if cached_file
    end
    module_function :lines

    #
    # Return an array of line numbers that could be stopping points in a given
    # Ruby source code string
    #
    def breakpoint_lines(src)
      name = "#{Time.new.to_i}_#{rand(2**31)}"
      iseq, lines = RubyVM::InstructionSequence.compile(src, name), {}

      iseq.disasm.each_line do |line|
        res = /^\d+ (?<insn>\w+)\s+.+\(\s*(?<lineno>\d+)\)$/.match(line)
        next unless res && res[:insn] == 'trace'

        lines[res[:lineno].to_i] = true
      end

      lines.keys
    end
    module_function :breakpoint_lines

    #
    # Returns an array of potential breakpoint lines in <filename>.
    #
    # The list will contain an entry for each distinct line event call so it is
    # possible (and possibly useful) for a line number appear more than once.
    #
    def stopping_points(filename, reload_on_change = true)
      cached = cache(filename, reload_on_change)
      return unless cached
      return cached.numbers if cached.numbers

      cached.numbers = breakpoint_lines(cached.lines.join)
      return unless cached.numbers

      cached.numbers
    end
    module_function :stopping_points

    #
    # Checks whether an entry in the cache is updated or not
    #
    def updated?(filename)
      stat, cach = File.stat(filename), @file_cache[filename]
      return false unless stat.mtime == cach.mtime && stat.size == cach.size

      true
    end
    module_function :updated?

    #
    # Updates cache entry for <filename>
    #
    def update(filename)
      lines = File.open(filename, 'r') { |f| f.readlines }
      stat = File.stat(filename)
      size, mtime = stat.size, stat.mtime

      @file_cache[filename] = FilecacheInfo.new(nil, lines, size, mtime)
    end
    module_function :update

    #
    # Deletes the cache entry for <filename>
    #
    def delete(filename)
      @file_cache.delete(filename)
      nil
    end
    module_function :delete
  end
end
