#
# Runs tests multiple times until one of them fails. This can help:
# * Checking for race conditions (that would manifest only sporadically) when
# tests involve multiple threads.
# * Watch for memory leaks.
#
# @example Tun tests 8 times for each Ruby in 2.0, 2.1 and 2.2
#
#   $ TIMES=8 rake loop_tests
#
# @example Run tests 1 time for each Ruby in 2.0, 2.1 and 2.2
#
#   $ TIMES=1 RUBIES=2.0,2.1 loop_tests.sh
#
# @example Run tests 3 times for each Ruby in 2.0 and 2.1
#
#   $ ./loop_tests.sh 3 2.0 2.1
#
desc 'Runs tests continuously'
task :loop_tests do
  compile = 'bundle exec rake compile'
  run = 'bundle exec rake test'

  iterations = ENV['TIMES'] || 8
  rubies = ENV['RUBIES'] ? ENV['RUBIES'].split(',') : %w(2.0 2.1 2.2)

  rubies.each do |version|
    exit($CHILD_STATUS) unless system("rvm #{version} do #{compile}")

    iterations.times do
      exit($CHILD_STATUS) unless system("rvm #{version} do #{run}")
    end
  end
end

#
# Filters all processes but the loop_tests task from `ps` output.
#
# Some shell trickery is used:
# * Using `[l]oop_tests` instead of `loop_tests` excludes the `grep` process
# itself from the matching processes.
# * Using `[^_][l]oop_tests` instead of just `[l]oop_tests` excludes the
# `watch_loop_tests` task as well.
#
def loop_tests_process
  'ps aux | grep [^_][l]oop_tests'
end

#
# Watch memory usage of the loop_tests task.
#
desc 'Watch memory use of the loop_tests task'
task :watch_loop_tests do
  system "watch \"#{loop_tests_process}\""
end
