* to test a file you can use:
    bundle exec rake test test/commands/break_test.rb
or as recommended in CONTRIBUTING.md:
    bin/minitest test/commands/break_test.
* someday i was testing and everything was working fine, and then all of the sudden bundle stopped working and I could not test anymore.
  - the solution was to run the command 'bin/rake compile' as recommended in CONTRIBUTING.md
