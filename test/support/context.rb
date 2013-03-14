module Byebug
  class Context

    def inspect
      values = %w{
        thread thnum stop_reason tracing ignored? stack_size dead? frame_line frame_file frame_self
      }.map do |field|
        "#{field}: #{send(field)}"
      end.join(", ")
      "#<Byebug::Context #{values}>"
    end

  end
end
