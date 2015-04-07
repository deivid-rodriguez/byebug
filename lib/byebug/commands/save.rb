require 'byebug/command'

module Byebug
  #
  # Save current settings to use them in another debug session.
  #
  class SaveCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s* sa(?:ve)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      file = File.open(@match[1] || Setting[:savefile], 'w')

      save_breakpoints(file)
      save_catchpoints(file)
      save_displays(file)
      save_settings(file)

      print pr('save.messages.done', path: file.path)
      file.close
    end

    def description
      <<-EOD
        save[ FILE]

        Saves current byebug state to FILE as a script file. This includes
        breakpoints, catchpoints, display expressions and some settings. If no
        filename is given, we will fabricate one.

        Use the "source" command in another debug session to restore them.
      EOD
    end

    private

    def save_breakpoints(file)
      Byebug.breakpoints.each do |b|
        file.puts "break #{b.source}:#{b.pos}#{" if #{b.expr}" if b.expr}"
      end
    end

    def save_catchpoints(file)
      Byebug.catchpoints.keys.each do |c|
        file.puts "catch #{c}"
      end
    end

    def save_displays(file)
      @state.display.each { |d| file.puts "display #{d[1]}" if d[0] }
    end

    def save_settings(file)
      %w(autoeval autoirb autolist basename).each do |setting|
        file.puts "set #{setting} #{Setting[setting.to_sym]}"
      end
    end
  end
end
