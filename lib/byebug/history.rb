module Byebug
  class History
    attr_accessor :file, :max_size

    def initialize(file = '.byebug_hist', max_size = 256)
      @file, @max_size = File.expand_path(file), max_size
      self.load
    end

    def load
      open(@file, 'r') do |file|
        file.each do |line|
          line.chomp!
          Readline::HISTORY << line
        end
      end if File.exist?(@file)
    end

    def save
      open(@file, 'w') do |file|
        Readline::HISTORY.to_a.last(@max_size).each do |line|
          file.puts line unless line.strip.empty?
        end
      end
    end

    def to_s(size = @max_size)
      n_entries = Readline::HISTORY.length < size ? Readline::HISTORY.length : size

      first = Readline::HISTORY.length - n_entries
      commands = Readline::HISTORY.to_a.last(n_entries)

      s = ''
      commands.each_with_index do |command, index|
        s += ("%5d  %s\n" % [first + index + 1, command])
      end

      return s
    end
  end
end
