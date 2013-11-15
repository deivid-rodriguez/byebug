module Byebug
  class LocalInterface < Interface
    attr_accessor :command_queue, :history_length, :history_save, :histfile
    attr_accessor :restart_file

    FILE_HISTORY = ".byebug_hist" unless defined?(FILE_HISTORY)

    def initialize()
      super
      @command_queue = []
      @have_readline = false
      @history_save = true
      @history_length = ENV["HISTSIZE"] ? ENV["HISTSIZE"].to_i : 256
      @histfile = File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", FILE_HISTORY)
      open(@histfile, 'r') do |file|
        file.each do |line|
          line.chomp!
          Readline::HISTORY << line
        end
      end if File.exist?(@histfile)
      @restart_file = nil
    end

    def read_command(prompt)
      readline(prompt, true)
    end

    def confirm(prompt)
      readline(prompt, false)
    end

    def print(*args)
      STDOUT.printf(escape(format(*args)))
    end

    def close
    end

    # Things to do before quitting
    def finalize
      if Byebug.respond_to?(:save_history)
        Byebug.save_history
      end
    end

    def readline_support?
      @have_readline
    end

    private

      begin
        require 'readline'
        class << Byebug
          @have_readline = true
          define_method(:save_history) do
            iface = self.handler.interface
            iface.histfile ||= File.join(ENV["HOME"]||ENV["HOMEPATH"]||".",
                                    FILE_HISTORY)
            open(iface.histfile, 'w') do |file|
              Readline::HISTORY.to_a.last(iface.history_length).each do |line|
                file.puts line unless line.strip.empty?
              end if defined?(iface.history_save) and iface.history_save
            end rescue nil
          end
          public :save_history
        end

        def readline(prompt, hist)
          Readline::readline(prompt, hist)
        rescue Interrupt
          print "^C\n"
          retry
        end
      rescue LoadError
        def readline(prompt, hist)
          @histfile = ''
          @hist_save = false
          STDOUT.print prompt
          STDOUT.flush
          line = STDIN.gets
          exit unless line
          line.chomp!
          line
        end
      end
  end
end
