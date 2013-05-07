require 'mkmf'

if RUBY_VERSION < "2.0"
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

$CFLAGS = '-Wall -Werror'
$CFLAGS += ' -g3' if ENV['debug']

dir_config("ruby")
create_makefile("byebug")
