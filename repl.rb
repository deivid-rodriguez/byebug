#!/usr/bin/env ruby
# frozen_string_literal: true

require "readline"

def with_repl_like_sigint
  orig_handler = trap("INT") { raise Interrupt }
  yield
rescue Interrupt
  puts("^C")
  retry
ensure
  trap("INT", orig_handler)
end

with_repl_like_sigint { Readline.readline("foo") }
