require 'byebug/state'

module Byebug
  #
  # Controls state of Byebug's REPL when in normal mode
  #
  class RegularState < State
    attr_accessor :context, :frame, :display, :file, :line, :prev_line
    attr_writer :interface

    def initialize(context, display, file, interface, line)
      super(interface)
      @context = context
      @display = display
      @file = file
      @frame = 0
      @line = line
      @prev_line = nil
      @proceed = false
    end

    extend Forwardable
    def_delegators :@interface, :errmsg, :puts, :print, :confirm

    #
    # Checks whether that execution can proceed
    #
    def proceed?
      @proceed
    end

    #
    # Signals the REPL that the execution can proceed
    #
    def proceed
      @proceed = true
    end

    include FileFunctions
    #
    # Current (formatted) location
    #
    def location
      l = "#{normalize(file)} @ #{line}\n"
      l += "#{get_line(file, line)}\n" unless %w((irb) -e').include?(file)
      l
    end

    #
    # Builds a string containing the class associated to frame number +pos+
    # or an empty string if the current +callstyle+ setting is 'short'
    #
    # @param pos [Integer] Frame position.
    #
    def frame_class(pos)
      return '' if Setting[:callstyle] == 'short'

      klass = context.frame_class(pos)
      return '' if klass.to_s.empty?

      "#{klass}."
    end

    #
    # Builds a formatted string containing information about block and method
    # of the frame in position +pos+
    #
    # @param pos [Integer] Frame position.
    #
    def frame_block_and_method(pos)
      deco_regexp = /((?:block(?: \(\d+ levels\))?|rescue) in )?(.+)/
      deco_method = "#{context.frame_method(pos)}"
      block_and_method = deco_regexp.match(deco_method)[1..2]
      block_and_method.map { |x| x.nil? ? '' : x }
    end

    #
    # Builds a string containing all available args in frame number +pos+, in a
    # verbose or non verbose way according to the value of the +callstyle+
    # setting
    #
    # @param pos [Integer] Frame position.
    #
    def frame_args(pos)
      args = context.frame_args(pos)
      return '' if args.empty?

      locals = context.frame_locals(pos) unless Setting[:callstyle] == 'short'
      my_args = args.map do |arg|
        case arg[0]
        when :block then prefix, default = '&', 'block'
        when :rest then prefix, default = '*', 'args'
        else prefix, default = '', nil
        end

        kls = if Setting[:callstyle] == 'short' || arg[1].nil? || locals.empty?
                ''
              else
                "##{locals[arg[1]].class}"
              end

        "#{prefix}#{arg[1] || default}#{kls}"
      end

      "(#{my_args.join(', ')})"
    end

    #
    # Builds a formatted string containing information about current method
    # call in frame number +pos+.
    #
    # @param pos [Integer] Frame position.
    #
    def frame_call(pos)
      block, method = frame_block_and_method(pos)

      block + frame_class(pos) + method + frame_args(pos)
    end

    #
    # Formatted filename in frame number +pos+
    #
    # @param pos [Integer] Frame position.
    #
    def frame_file(pos)
      fullpath = context.frame_file(pos)
      Setting[:fullpath] ? fullpath : shortpath(fullpath)
    end

    #
    # Line number in frame number +pos+
    #
    # @param pos [Integer] Frame position.
    #
    def frame_line(pos)
      context.frame_line(pos)
    end

    #
    # Properly formatted frame number of frame in position +pos+
    #
    # @param pos [Integer] Frame position.
    #
    def frame_pos(pos)
      format('%-2d', pos)
    end

    #
    # Formatted mark for number of frame in position +pos+. The mark can
    # contain the current frame symbo (-->), the c_frame symbol (ͱ--) or both
    #
    # @param pos [Integer] Frame position.
    #
    def frame_mark(pos)
      mark = frame == pos ? '-->' : '   '

      c_frame?(pos) ? mark + ' ͱ--' : mark
    end

    #
    # Checks whether the frame in position +pos+ is a c-frame or not
    #
    # @param pos [Integer] Frame position.
    #
    def c_frame?(pos)
      context.frame_binding(pos).nil?
    end

    private

    def shortpath(fullpath)
      components = Pathname(fullpath).each_filename.to_a
      return fullpath if components.size <= 2

      File.join('...', components[-3..-1])
    end
  end
end
