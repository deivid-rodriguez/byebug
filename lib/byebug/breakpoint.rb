module Byebug
  #
  # Implements breakpoints
  #
  class Breakpoint
    #
    # First breakpoint, in order of creation
    #
    def self.first
      Byebug.breakpoints.first
    end

    #
    # Last breakpoint, in order of creation
    #
    def self.last
      Byebug.breakpoints.last
    end

    #
    # Adds a new breakpoint
    #
    # @param [String] file
    # @param [Fixnum] line
    # @param [String] expr
    #
    def self.add(file, line, expr = nil)
      breakpoint = Breakpoint.new(file, line, expr)
      Byebug.breakpoints << breakpoint
      breakpoint
    end

    #
    # Removes a breakpoint
    #
    # @param [integer] breakpoint number
    #
    def self.remove(id)
      Byebug.breakpoints.reject! { |b| b.id == id }
    end

    #
    # True if there's no breakpoints
    #
    def self.none?
      Byebug.breakpoints.empty?
    end

    #
    # Prints all information associated to the breakpoint
    #
    def inspect
      meths = %w(id pos source expr hit_condition hit_count hit_value enabled?)
      values = meths.map do |field|
        "#{field}: #{send(field)}"
      end.join(', ')
      "#<Byebug::Breakpoint #{values}>"
    end
  end
end
