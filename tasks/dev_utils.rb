#
# Runs tests repeatedly against different ruby versions. Aborts when a test
# fails.
#
# Useful for:
# * Checking for race conditions (that would manifest only sporadically) when
# tests involve multiple threads.
# * Watching for memory leaks.
#
class LoopRunner
  #
  # @param iterations [Integer] number of loops of tests to run
  # @param rubies [Array] target Ruby version
  # @param manager [Array] Ruby version manager to use ('rvm' or 'chruby')
  #
  def initialize(iterations, rubies, manager)
    @iterations = iterations
    @rubies = rubies
    @manager = manager
  end

  def run
    @rubies.each do |version|
      run_command(version, 'gem install bundler --no-document')
      run_command(version, 'bundle')
      run_command(version, 'bundle exec rake clobber compile')

      @iterations.times { run_command(version, 'bundle exec rake test') }

      run_command(version, 'bundle exec rake sign_hooks overcommit')
    end
  end

  def run_command(version, cmd)
    command = if @manager == 'rvm'
                "rvm #{version} do #{cmd}"
              else
                "chruby-exec #{version} -- #{cmd}"
              end

    Bundler.with_clean_env { system(command) }
  end
end

#
# @example Tun tests 8 times for each supported Ruby
#
#   $ rake loop_tests
#
# @example Run tests 1 time for each supported Ruby
#
#   $ TIMES=1 rake loop_tests
#
# @example Run tests 1 time for each Ruby in 2.2 and 2.3
#
#   $ TIMES=1 RUBIES=2.2,2.3 rake loop_tests
#
# @example Run tests 1 time using Ruby 2.3 and rvm
#
#   $ MANAGER=rvm TIMES=1 RUBIES=2.3 rake loop_tests
#
desc 'Runs tests continuously'
task :loop_tests do
  iterations = (ENV['TIMES'] || '8').to_i
  rubies = ENV['RUBIES'] ? ENV['RUBIES'].split(',') : %w[2.2 2.3]
  ruby_manager = ENV['MANAGER'] || 'chruby'

  LoopRunner.new(iterations, rubies, ruby_manager).run
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
