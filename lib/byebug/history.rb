require 'readline'

module Byebug
  #
  # Handles byebug's history of commands.
  #
  class History
    class << self
      def load
        open(Setting[:histfile], 'r') do |file|
          file.each do |line|
            line.chomp!
            Readline::HISTORY << line
          end
        end if File.exist?(Setting[:histfile])
      end

      def save
        open(Setting[:histfile], 'w') do |file|
          Readline::HISTORY.to_a.last(Setting[:histsize]).each do |line|
            file.puts line unless line.strip.empty?
          end
        end
      end

      def to_s(size = Setting[:histsize])
        rl_size = Readline::HISTORY.length
        n_entries = rl_size < size ? rl_size : size

        first = rl_size - n_entries
        commands = Readline::HISTORY.to_a.last(n_entries)

        s = ''
        commands.each_with_index do |command, index|
          s += format("%5d  %s\n", first + index + 1, command)
        end

        s
      end
    end
  end
end
