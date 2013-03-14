class Byebug::Processor
  class << self
    def print(message)
      Byebug.handler.interface.print_queue << message
    end
  end
end
