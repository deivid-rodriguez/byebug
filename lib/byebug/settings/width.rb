module Byebug
  class WidthSetting < Setting
    def initialize
      if ENV['COLUMNS'] =~ /^\d+$/
        @value = ENV['COLUMNS'].to_i
      elsif STDIN.tty? && exists?('stty')
        @value = `stty size`.scan(/\d+/)[1].to_i
      else
        @value = 160
      end
    end

    def help
      "Number of characters per line in byebug's output"
    end

    def to_s
      "Maximum width of byebug's output is #{value}"
    end

    private

      def exists?(command)
        ENV['PATH'].split(File::PATH_SEPARATOR).any? do |d|
          File.exist?(File.join(d, command))
        end
      end
  end
end
