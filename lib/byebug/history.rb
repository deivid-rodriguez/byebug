require 'readline'

module Byebug
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
