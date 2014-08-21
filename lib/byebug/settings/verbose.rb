module Byebug
  #
  # Setting to show verbose output about TracePoint API events.
  #
  class VerboseSetting < Setting
    def banner
      'Enable verbose output of TracePoint API events'
    end

    def value=(v)
      Byebug.verbose = v
    end

    def value
      Byebug.verbose?
    end
  end
end
