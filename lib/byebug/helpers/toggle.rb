require 'byebug/helpers/parse'

module Byebug
  module Helpers
    #
    # Utilities to assist breakpoint/display enabling/disabling.
    #
    module ToggleHelper
      include ParseHelper

      def enable_disable_breakpoints(is_enable, args)
        return errmsg(pr('toggle.errors.no_breakpoints')) if Breakpoint.none?

        all_breakpoints = Byebug.breakpoints.sort_by(&:id)
        if args.nil?
          selected_breakpoints = all_breakpoints
        else
          selected_ids = []
          args.split(/ +/).each do |pos|
            last_id = all_breakpoints.last.id
            pos, err = get_int(pos, "#{is_enable} breakpoints", 1, last_id)
            return errmsg(err) unless pos

            selected_ids << pos
          end
          selected_breakpoints = all_breakpoints.select do |b|
            selected_ids.include?(b.id)
          end
        end

        selected_breakpoints.each do |b|
          enabled = ('enable' == is_enable)
          if enabled && !syntax_valid?(b.expr)
            return errmsg(pr('toggle.errors.expression', expr: b.expr))
          end

          b.enabled = enabled
        end
      end

      def enable_disable_display(is_enable, args)
        display = @state.display
        return errmsg(pr('toggle.errors.no_display')) if 0 == display.size

        selected_displays = args.nil? ? [1..display.size + 1] : args.split(/ +/)

        selected_displays.each do |pos|
          pos, err = get_int(pos, "#{is_enable} display", 1, display.size)
          return errmsg(err) unless err.nil?

          display[pos - 1][0] = ('enable' == is_enable)
        end
      end
    end
  end
end
