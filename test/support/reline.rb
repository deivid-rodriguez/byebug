# frozen_string_literal: true

require "reline"

Reline.send(:remove_const, "IOGate")
Reline.const_set("IOGate", Reline::GeneralIO)
Reline.core.config.instance_variable_set(:@test_mode, true)
Reline.core.config.reset
Reline.input = $stdin
