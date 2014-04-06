module Byebug
  class History
    attr_accessor :file, :size

    def initialize(file = '.byebug_hist', size = 256)
      @file, @size = File.expand_path(file), size
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
        Readline::HISTORY.to_a.last(@size).each do |line|
          file.puts line unless line.strip.empty?
        end
      end
    end
  end
end
