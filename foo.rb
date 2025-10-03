# frozen_string_literal: true

require "open3"

env = { "RUBYOPT"=>"-I #{Dir.pwd}/lib" }
out, st = Open3.capture2e(env, Gem.ruby, "exe/byebug", "-I", "dir", "#{Dir.pwd}/test/support/utils.rb", stdin_data: "")
puts out
