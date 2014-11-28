desc 'Run a test in looped mode so that you can look for memory leaks'
task :test_loop do
  code = %(loop{ require '#{$ARGV[1]}' })
  cmd = %(ruby -Itest -e "#{ code }")
  system cmd
end

desc 'Watch memory use of a looping test'
task :test_loop_mem do
  system "watch \"ps aux | grep -v 'sh -c r' | grep [I]test\""
end
