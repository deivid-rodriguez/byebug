if RUBY_VERSION < '2.0'
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
  $CFLAGS ||= ''
  $CFLAGS += ' -Wall -Werror -Wno-unused-parameter'
  $CFLAGS += ' -gdwarf-2 -g3 -O0' if ENV['debug']
end

dir_config('ruby')
create_makefile('byebug/byebug')
