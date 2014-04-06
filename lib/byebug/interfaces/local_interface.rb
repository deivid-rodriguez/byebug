module Byebug
  class LocalInterface < Interface
    attr_accessor :command_queue, :hist_size, :hist_save, :hist_file
    attr_accessor :restart_file

    FILE_HISTORY = ".byebug_hist" unless defined?(FILE_HISTORY)

    def initialize()
      super
      @command_queue = []
      @have_readline = false
      @hist_save = true
      @hist_size = ENV["HISTSIZE"] ? ENV["HISTSIZE"].to_i : 256
      @hist_file = File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", FILE_HISTORY)
      open(@hist_file, 'r') do |file|
        file.each do |line|
          line.chomp!
          Readline::HISTORY << line
        end
      end if File.exist?(@hist_file)
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
            iface.hist_file ||= File.join(ENV["HOME"]||ENV["HOMEPATH"]||".",
                                    FILE_HISTORY)
            open(iface.hist_file, 'w') do |file|
              Readline::HISTORY.to_a.last(iface.hist_size).each do |line|
                file.puts line unless line.strip.empty?
              end if defined?(iface.hist_save) and iface.hist_save
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
          @hist_file = ''
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
