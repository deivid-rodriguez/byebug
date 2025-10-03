# frozen_string_literal: true

require "open3"

env = { "RUBYOPT"=>"-I #{Dir.pwd}/lib" }
out, st = Open3.capture2e(env, Gem.ruby, "repl.rb", stdin_data: "")
puts out
