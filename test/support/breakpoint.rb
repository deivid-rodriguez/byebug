module Byebug
  #
  # Extends Breakpoint class for easier inspection
  #
  class Breakpoint
    def inspect
      meths = %w(id pos source expr hit_condition hit_count hit_value enabled?)
      values = meths.map do |field|
        "#{field}: #{send(field)}"
      end.join(', ')
      "#<Byebug::Breakpoint #{values}>"
    end
  end
end
