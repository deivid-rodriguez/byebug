module Byebug
  #
  # Special setting to flag that byebug is being tested.
  #
  # FIXME: make this private.
  #
  class TestingSetting < Setting
    def banner
      'Used when testing byebug'
    end
  end
end
