# frozen_string_literal: true

require "reline"

new_io_gate = Reline::Dumb.new(encoding: Encoding::UTF_8)
Reline.send(:remove_const, "IOGate")
Reline.const_set("IOGate", new_io_gate)
