module Byebug
  class ScriptInterface < Interface
    attr_accessor :command_queue, :history_length, :history_save, :histfile
    attr_accessor :restart_file

    def initialize(file, out, verbose=false)
      super()
      @command_queue = []
      @file = file.respond_to?(:gets) ? file : open(file)
      @out = out
      @verbose = verbose
      @history_save = false
      @history_length = 256
      @histfile = ''
    end

    def finalize
    end

    def read_command(prompt)
      while result = @file.gets
        puts "# #{result}" if @verbose
        next if result =~ /^\s*#/
        next if result.strip.empty?
        return result.chomp
      end
    end

    def readline_support?
      false
    end

    def confirm(prompt)
      'y'
    end

    def print(*args)
      @out.printf(*args)
    end

    def close
      @file.close
    end
  end
end
