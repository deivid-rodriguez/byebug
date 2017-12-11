#
# For the `release` task
#
require 'bundler/gem_tasks'

#
# For automatic creation of github releases
#
require 'chandler/tasks'

#
# Add chandler as a prerequisite for `rake release`
#
task 'release:rubygem_push' => 'chandler:push'

#
# Prepend DevKit into compilation phase
#
if Gem.win_platform?
  desc 'Activates DevKit'
  task :devkit do
    begin
      require 'devkit'
    rescue LoadError
      abort 'Failed to load DevKit required for compilation'
    end
  end

  task compile: :devkit
end

#
# For the `compile` task
#
require 'rake/extensiontask'

spec = Gem::Specification.load('byebug.gemspec')
Rake::ExtensionTask.new('byebug', spec) { |ext| ext.lib_dir = 'lib/byebug' }

#
# Test task
#
desc 'Runs the test suite'
task :test do
  require_relative 'script/minitest_runner'
  # Set high to bypass, adds -v option and timeout to testing when true
  if RUBY_VERSION >= '2.5'
    require 'timeout'
    ENV['TESTOPTS'] = "#{(ENV['TESTOPTS'] || '')} -v".strip
    begin
      Timeout.timeout(180) { exit 1 unless MinitestRunner.new.run }
    rescue Timeout::Error
      STDERR.puts "\n\nTests timed out in 3 minutes"
      exit 1
    end
  else
    exit 1 unless MinitestRunner.new.run
  end
end

desc 'Run overcommit hooks manually'
task :overcommit do
  exit 1 unless system('bundle exec overcommit --run')
end

desc 'Sign overcommit hooks'
task :sign_hooks do
  system('bundle exec overcommit --sign')
  system('bundle exec overcommit --sign pre-commit')
end

task default: %i[compile test overcommit]

#
# Custom tasks for development
#
require_relative 'tasks/dev_utils.rb'

#
# Generate docs
#
require 'yard'
YARD::Rake::YardocTask.new
