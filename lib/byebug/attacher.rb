# frozen_string_literal: true

#
# Main Container for all of Byebug's code
#
module Byebug
  #
  # Starts byebug, and stops at the first line of user's code.
  #
  def self.attach
    require "byebug/core"

    unless started?
      self.mode = :attached

      start
      run_init_script
    end

    current_context.step_out(3, true)
  end

  def self.spawn(host = "localhost", port = nil)
    require "byebug/core"

    self.wait_connection = true
    start_server(host, port || PORT)
  end
end

#
# Adds a `byebug` method to the Kernel module.
#
# Dropping a `byebug` call anywhere in your code, you get a debug prompt.
#
module Kernel
  def byebug
    Byebug.attach
  end

  def remote_byebug(host = "localhost", port = nil)
    Byebug.spawn(host, port)

    Byebug.attach
  end

  alias debugger byebug
end
