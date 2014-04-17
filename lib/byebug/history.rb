require 'readline'

module Byebug
  class History
    DEFAULT_FILE = File.expand_path("#{ENV['HOME']||'.'}/.byebug_hist")
    DEFAULT_MAX_SIZE = 256

    @file = DEFAULT_FILE
    @max_size = DEFAULT_MAX_SIZE

    class << self
      attr_accessor :file, :max_size

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
end
