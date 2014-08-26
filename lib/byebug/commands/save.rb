module Byebug
  #
  # Utilities for the save command.
  #
  module SaveFunctions
    # Create a temporary file to write in if file is nil
    def open_save
      require 'tempfile'
      file = Tempfile.new('byebug-save')
      # We want close to not unlink, so redefine.
      def file.close
        @tmpfile.close if @tmpfile
      end
      file
    end
  end

  #
  # Save current settings to use them in another debug session.
  #
  class SaveCommand < Command
    self.allow_in_control = true

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
      %w(autoeval autoirb autolist basename testing).each do |setting|
        file.puts "set #{setting} #{Setting[setting.to_sym]}"
      end
    end

    def regexp
      /^\s* sa(?:ve)? (?:\s+(\S+))? \s*$/x
    end

    def execute
      if !@match[1]
        file = open_save
      else
        file = open(@match[1], 'w')
      end
      save_breakpoints(file)
      save_catchpoints(file)
      save_displays(file)
      save_settings(file)
      puts "Saved to '#{file.path}'"
      @state.interface.restart_file = file.path if @state && @state.interface
      file.close
    end

    class << self
      def names
        %w(save)
      end

      def description
        %(save[ FILE]

          Saves current byebug state to FILE as a script file. This includes
          breakpoints, catchpoints, display expressions and some settings. If
          no filename is given, we will fabricate one.

          Use the "source" command in another debug session to restore them.)
      end
    end
  end
end
