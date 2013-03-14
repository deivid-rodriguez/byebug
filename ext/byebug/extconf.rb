require 'mkmf'

if RUBY_VERSION < "2.0"
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

$CFLAGS = '-Wall -Werror'
$CFLAGS += ' -g3' if ENV['debug']

dir_config("ruby")
create_makefile("byebug")

#if !Byebug::RubyCoreSource.create_makefile_with_core(hdrs, "ruby_debug")
#  STDERR.print("Makefile creation failed\n")
#  STDERR.print("*************************************************************\n\n")
#  STDERR.print("  NOTE: If your headers were not found, try passing\n")
#  STDERR.print("        --with-ruby-include=PATH_TO_HEADERS      \n\n")
#  STDERR.print("*************************************************************\n\n")
#  exit(1)
#end
